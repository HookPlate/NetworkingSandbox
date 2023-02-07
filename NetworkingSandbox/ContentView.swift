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
    static let headlines = EndPoint(path: "headlinesT.json", type: [News].self)
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
    
    //another fetch to handle retrying. attempts: you must tell me how many attempts to make anf a 2 second delay between each fetch. Much of it is the same as the orginal fetch() because we can call down to that? Known as an overload (another more complex option on fetch?
    func fetch<T>(_ resource: EndPoint<T>, with data: Data? = nil, attempts: Int, retryDelay:Double = 1) async throws -> T {
        //We have to have this becasue we're making attempts now. Try once - it failes, try again - it failed, try again - response.
        do {
            print("Attempting to fetch (Attempts remaining: \(attempts)")
            //this is the original fetch method. That, if it goes wrong will fail on line 96, or if the decode fails it'll go wrong on line 99, either way it'll throw an error (look at the function signature) and jump straight to the below catch.
            return try await fetch(resource, with: data)
            //we've tried our original fetch request and it went wrong, what do you wwant to do.
        } catch {
            if attempts > 1 {
                //Sleep for some amount of time, I think this gets faster and faster as retryDelay gets smaller - no becasue retryDelay never changes from 1. These new duration things in 14.2 are Integers and .seconds is a double (which you'd normally use) therefore he converts the retryDelay: Double into an Int using milliseinds.
                try await Task.sleep(for: .milliseconds(Int(retryDelay * 1000)))
                //so what's happening here is the first time we try to fetch we do it on line 108, that's one fetch calling a differrent overload of fetch(), if that fails we wait a certain amount of time and then call ourselves recursively with attempts minus 1.
                return try await fetch(resource, with: data, attempts: attempts - 1, retryDelay: retryDelay)
            } else {
                //we tried, we've gone through all our attempts recursively calling ourself, they all failed - we'll send back whetever error we receive. So if the call on 108 (because each time we're trying that block don't forget when we call ourselves) throws an error we'll send it back, bubble it upwards.
                throw error
            }
        }
    }
}

struct NetworkManagerKey: EnvironmentKey {
    static var defaultValue = NetworkManager(environment: .testing)
    
}

extension EnvironmentValues {
    var networkManager: NetworkManager {
        get { self[NetworkManagerKey.self] }
        set { self[NetworkManagerKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()

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
                //we change the below so we can test our retry support. We did this having put a spelling mistake on line 32. It prints out to the console Attempting to fetch (Attempts remaining: 5 all the way down to 1 each every second then prints catch block below.
                headlines = try await networkManager.fetch(.headlines, attempts: 5)
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
