//
//  ContentView.swift
//  NetworkingSandbox
//
//  Created by Yoli on 04/02/2023.
//

import SwiftUI

struct News: Decodable, Identifiable {
    var id: Int
    var title: String
    var strap: String
    var url: URL
}

struct Message: Decodable, Identifiable {
    var id: Int
    var from: String
    var text: String
}

struct EndPoint<T: Decodable> {
    var path: String
    var type: T.Type
    var method = HTTPMethod.get
    var headers = [String: String]()
    
}

extension EndPoint where T == [News] {
    static let headlines = EndPoint(path: "headlines.json", type: [News].self)
}

extension EndPoint where T == [Message] {
    static let messages = EndPoint(path: "messages.json", type: [Message].self)
}

enum HTTPMethod: String {
    case delete, get, patch, post, put
    
    var rawValue: String {
        String(describing: self).uppercased()
    }
    
}

struct AppEnvironment {
    var name: String
    var baseURL: URL
    var session: URLSession
    
    static let production = AppEnvironment(
        name: "Production",
        baseURL: URL(string: "https://hws.dev")!,
        session: {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = [
                "API-key": "production-key-from-keychain"
            ]
            return URLSession(configuration: configuration)
        }()
    )
    
    #if DEBUG
        static let testing = AppEnvironment(
            name: "Testing",
            baseURL: URL(string: "https://hws.dev")!,
            session: {
                let configuration = URLSessionConfiguration.ephemeral
                configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                
                configuration.httpAdditionalHeaders = ["APIKey": "test-key" ]
                
                return URLSession(configuration: configuration)
            }()
        )
    
    #endif
    
    
}


struct NetworkManager {
    var environment: AppEnvironment
    
    func fetch<T>(_ resource: EndPoint<T>, with data: Data? = nil) async throws -> T {
        guard let url = URL(string: resource.path, relativeTo: environment.baseURL) else {
            throw URLError(.unsupportedURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = data
        request.allHTTPHeaderFields = resource.headers
        var (data, _) = try await environment.session.data(for: request)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

struct NetworkManagerKey: EnvironmentKey {
    //Note this is the key - play it safe by having testing as a default.
    static var defaultValue = NetworkManager(environment: .testing)
    
}
//so we can read and write the key
extension EnvironmentValues {
    //I think we use this when we indsert it into the main apps environment.
    var networkManager: NetworkManager {
        get { self[NetworkManagerKey.self] }
        set { self[NetworkManagerKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()
    //this is all very clever but currently every every newtwork enabled view needs to make its own NetworkManager and decide its own environment - silly.
    //let networkManager = NetworkManager(environment: .production)
    //last step is to read it out from the environment here. We don't want to have to worry here if we're in testing or production, we don;t care, this view shouldn't have to care, we're getting rid of all the possible places we can screw this up.
    @Environment(\.networkManager) var networkManager
    
    var body: some View {
        List {
            Section("Headlines") {
                ForEach(headlines) { headline in
                    VStack(alignment: .leading) {
                        Text(headline.title)
                            .font(.headline)
                        
                        Text(headline.strap)
                    }
                }
            }
            
            Section("Messages") {
                ForEach(messages) { message in
                    VStack(alignment: .leading) {
                        Text(message.from)
                            .font(.headline)
                        
                        Text(message.text)
                    }
                }
            }
        }
        .task {
            do {
                headlines = try await networkManager.fetch(.headlines)
                messages = try await networkManager.fetch(.messages)
                
            } catch {
                print("Error handling is a smart move!")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
