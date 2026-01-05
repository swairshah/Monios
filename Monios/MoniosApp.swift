//
//  MoniosApp.swift
//  Monios
//
//  Created by Swair Shah on 1/4/26.
//

import SwiftUI
import GoogleSignIn

@main
struct MoniosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
