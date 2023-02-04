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

struct ContentView: View {
    @State private var headlines = [News]()
    @State private var messages = [Message]()
    
    
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
            //he purposefully made this handle two completely different kinds of data. They're not related to each other but you'll see why in a moment.
            do {
                //  1 get the url
                let headlinesURL = URL(string: "https://hws.dev/headlines.json")!
                let messagesURL = URL(string: "https://hws.dev/messages.json")!
                //  2 get the data from url (this is done asynchonously)
                let (headlineData, _) = try await URLSession.shared.data(from: headlinesURL)
                let (messageData, _) = try await URLSession.shared.data(from: messagesURL)
                //  3 decode the data
                
                headlines = try JSONDecoder().decode([News].self, from: headlineData)
                messages = try JSONDecoder().decode([Message].self, from: messageData)
                //  4 catch all those important errors
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
