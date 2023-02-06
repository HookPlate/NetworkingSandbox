//
//  NetworkingSandboxApp.swift
//  NetworkingSandbox
//
//  Created by Yoli on 04/02/2023.
//

import SwiftUI

@main
struct NetworkingSandboxApp: App {
    //create it once, and no it can't be a StateObject because that requires a class that conforms to the ObservableObject protocol. INterestingly since Paul has never seen the App struct above get destroyed it might be better to just delete the @State but hey.
    @State var networkManager = NetworkManager(environment: .testing)
    
    //he mentioned that soem companies might want to do this:
    /* if  DEBUG
     @State var networkManager = NetworkManager(environment: .testing)
     #else
     @State var networkManager = NetworkManager(environment: .production)
     #endIf
     */
    //that debug wont even compile without debug mode turned on.
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            //share it everywhere, now anything inside ContentView or children can now read that networkManager out.
                .environment(\.networkManager, networkManager)
        }
    }
}
