//
//  OnboardingView.swift
//  SwiftLapWatch Watch App
//

import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Track your swims")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 6) {
                    Text("• Reads heart rate, strokes, distance from your watch")
                    Text("• Saves workouts to Apple Health")
                    Text("• Counts your laps automatically")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
            }
            .padding()
        }
    }
}
