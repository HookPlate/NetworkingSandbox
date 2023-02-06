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
    //since we've now baked our base url into the environments we now just need paths to add to the base.
    var path: String
    var type: T.Type
    var method = HTTPMethod.get
    var headers = [String: String]()
    
}

extension EndPoint where T == [News] {
    //since we've change the endpoint to have a path we just do the last half, same below also.
    static let headlines = EndPoint(path: "headlines.json", type: [News].self)
}

extension EndPoint where T == [Message] {
    static let messages = EndPoint(path: "messages.json", type: [Message].self)
}

enum HTTPMethod: String {
    case delete, get, patch, post, put
    
    var rawValue: String {
        //read the value of self and make it uppercased
        String(describing: self).uppercased()
    }
    
}

//which environment are we running in right now?
struct AppEnvironment {
    //the name we refer to this thing as (production, sandbox whatever)
    var name: String
    //the base url for the endpint (perhaps a live production server for one or a testing.live.com or whatever for the other.
    var baseURL: URL
    //what URLSession do we want to use for it?
    var session: URLSession
    
    static let production = AppEnvironment(
        name: "Production",
        baseURL: URL(string: "https://hws.dev")!,
        //this is your production environment, things actually happening here. This matters, look out. The () on the ends means it's called straightaway.
        session: {
            let configuration = URLSessionConfiguration.default
            //whatever production level headers you want
            configuration.httpAdditionalHeaders = [
                "API-key": "production-key-from-keychain"
            ]
            return URLSession(configuration: configuration)
        }()
    )
    //add a testing environment but use the #if DEBUG which means never let this thing go outside of XCode. Never to the app store. Allows you to run on devices you pushed to from XCode but not to the App Store.
    #if DEBUG
        static let testing = AppEnvironment(
            name: "Testing",
            //he uses the same url here but normally it would be different.
            baseURL: URL(string: "https://hws.dev")!,
            session: {
                //here he's configured in a different way to immediately wipe out all caching. An exampkle of what you can do to make your two environments very different.
                let configuration = URLSessionConfiguration.ephemeral
                configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                
                configuration.httpAdditionalHeaders = ["APIKey": "test-key" ]
                
                return URLSession(configuration: configuration)
            }()
        )
    
    #endif
    
    
}


struct NetworkManager {
    //now this needs to know which environment (and therefore configuration) to work with
    var environment: AppEnvironment
    
    func fetch<T>(_ resource: EndPoint<T>, with data: Data? = nil) async throws -> T {
        //stick both components together and if it fails throw the error. Interesting that you start with the path and use relativeTo to stick on the beginning.
        guard let url = URL(string: resource.path, relativeTo: environment.baseURL) else {
            throw URLError(.unsupportedURL)
        }
        //we change the below to reference the above
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = data
        request.allHTTPHeaderFields = resource.headers
        //also, don;t just use the shared URLSession, use the one I configured earlier
        var (data, _) = try await environment.session.data(for: request)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()
    //finally this thing now needs to be told which environment to use, .production thanks to the static let
    let networkManager = NetworkManager(environment: .production)
    
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
