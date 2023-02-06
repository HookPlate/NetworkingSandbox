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
    var url: URL
    var type: T.Type
    //so it the read method by default but overridable.
    var method = HTTPMethod.get
    //tells the server that we're sending JSON - a String: String dictionary.
    var headers = [String: String]()
    
}

extension EndPoint where T == [News] {
    static let headlines = EndPoint(url: URL(string: "https://hws.dev/headlines.json")!, type: [News].self)
}

extension EndPoint where T == [Message] {
    static let messages = EndPoint(url: URL(string: "https://hws.dev/messages.json")!, type: [Message].self)
}

//a way of testing your reading and writing to and from a server works. He looked up the post /api/users on reqres.in. The type: is the type we expect back, the method is used because we're sending them a user for them to respond to, headers: this is where we tell it what we're actually sending (JSON.)
extension EndPoint where T == [String: String] {
    static let userTest  = EndPoint(url: URL(string: "https://reqres.in/api/users")!, type: [String: String].self, method: .post, headers: ["Content-Type": "application/json"])
}

enum HTTPMethod: String {
    case delete, get, patch, post, put
    
    var rawValue: String {
        //read the value of self and make it uppercased
        String(describing: self).uppercased()
    }
    
}

struct NetworkManager {
    //that with data: Data? = nil means we might (if it's a Post method to the server) want to attach some Data. SO it'll ignore it for any GET requests (reading from sever), we use this with data: when testing with reqres.in
    func fetch<T>(_ resource: EndPoint<T>, with data: Data? = nil) async throws -> T {
        var request = URLRequest(url: resource.url)
        //copy across our httpMethod into the request
        request.httpMethod = resource.method.rawValue
        //I suppose this body property is what you use to write JSON to the server. Here he says they’re both optional Data and nil by default. So both the property on the server and our optional data we're passing in.
        request.httpBody = data
        //copy it across so the server knows we're using JSON.
        request.allHTTPHeaderFields = resource.headers
        var (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()
    
    let networkManager = NetworkManager()
    
    var body: some View {
        List {
            Section("Headlines") {
                ForEach(headlines) { headline in
                    VStack(alignment: .leading) {
                        Text(headline.title)
                            .font(.headline)
                        //strap being the news
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
                
                //the call site for our test to reqres.in, the format name and job is told to us on reqres
                let user = ["name": "Bilbo Baggins", "job": "Ring Courier"]
                    //.userTest is the extension on Endpoint we made. The with: is teh optional data we added to our fetch function to handle sending of data.
                let response = try await networkManager.fetch(.userTest, with: JSONEncoder().encode(user))
                print(response)
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
