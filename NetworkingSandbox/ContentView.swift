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

struct EndPoint {
    var url: URL
    //gets the strings out of our code where they can be misstyped
    static let headlines = EndPoint(url: URL(string: "https://hws.dev/headlines.json")!)
    static let messages = EndPoint(url: URL(string: "https://hws.dev/messages.json")!)
}

struct NetworkManager {
    func fetch(_ resource: EndPoint) async throws -> Data {
        var request = URLRequest(url: resource.url)
        var (data, _) = try await URLSession.shared.data(for: request)
        return data
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
                let headlineData = try await networkManager.fetch(.headlines)
                let messageData = try await networkManager.fetch(.messages)
                
                headlines = try JSONDecoder().decode([News].self, from: headlineData)
                messages = try JSONDecoder().decode([Message].self, from: messageData)
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
