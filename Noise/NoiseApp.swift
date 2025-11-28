//
//  NoiseApp.swift
//  Noise
//
//  Created by Mikael Tyrsen on 11/25/25.
//

import SwiftUI
import UserNotifications

@main
struct NoiseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
