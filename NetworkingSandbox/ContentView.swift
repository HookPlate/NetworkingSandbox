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
}
//if that's the version of Endpoint we're talking about, give it the correlating static property. type is the type it'll decode.
extension EndPoint where T == [News] {
    static let headlines = EndPoint(url: URL(string: "https://hws.dev/headlines.json")!, type: [News].self)
}
//same as above
extension EndPoint where T == [Message] {
    static let messages = EndPoint(url: URL(string: "https://hws.dev/messages.json")!, type: [Message].self)
}
//Because we made tha bove generic this needs that generic thing passing through too
struct NetworkManager {
    func fetch<T>(_ resource: EndPoint<T>) async throws -> T {
        var request = URLRequest(url: resource.url)
        var (data, _) = try await URLSession.shared.data(for: request)
        //at this point instead of sending the data back directly we'll decode it here.
        //now it handles decoding for use baked right in.
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
            //and again this code becomes even simpler
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
