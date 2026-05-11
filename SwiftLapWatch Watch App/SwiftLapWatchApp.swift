//
//  SwiftLapWatchApp.swift
//  SwiftLapWatch Watch App
//
//  Created by Kimaya on 19/03/26.
//

import SwiftUI

@main
struct SwiftLapWatch_Watch_AppApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    @State private var hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                ContentView()
            } else {
                OnboardingView {
                    workoutManager.requestHealthAccess()
                    UserDefaults.standard.set(true, forKey: "hasOnboarded")
                    hasOnboarded = true
                }
            }
        }
    }
}
