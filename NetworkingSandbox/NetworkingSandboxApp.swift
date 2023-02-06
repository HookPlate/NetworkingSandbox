//
//  NetworkingSandboxApp.swift
//  NetworkingSandbox
//
//  Created by Yoli on 04/02/2023.
//

import SwiftUI

@main
struct NetworkingSandboxApp: App {
    @State var networkManager = NetworkManager(environment: .testing)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.networkManager, networkManager)
        }
    }
}
