//
//  ContentView.swift
//  SwiftLapWatch Watch App
//
//  Created by Kimaya on 20/03/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            if workoutManager.isWorkoutActive {
                // WORKOUT IN PROGRESS
                ScrollView {
                    VStack(spacing: 12) {
                        // Timer
                        Text(workoutManager.formatTime(workoutManager.elapsedSeconds))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatBox(title: "Laps", value: "\(workoutManager.lapCount)", icon: "arrow.triangle.2.circlepath")
                            StatBox(title: "Heart", value: "\(Int(workoutManager.heartRate))", icon: "heart.fill", color: .red)
                            StatBox(title: "Strokes", value: "\(workoutManager.strokeCount)", icon: "figure.pool.swim")
                            StatBox(title: "Pace", value: workoutManager.currentPace, icon: "speedometer")
                        }
                        
                        // Distance
                        HStack {
                            Image(systemName: "ruler")
                            Text("\(Int(workoutManager.distance))m")
                                .font(.title3.bold())
                        }
                        .foregroundColor(.green)
                        
                        // Fatigue
                        Text(workoutManager.fatigueLevel)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(fatigueColor.opacity(0.3))
                            .cornerRadius(8)
                        
                        // Buttons
                        HStack(spacing: 20) {
                            Button(action: { workoutManager.markLap() }) {
                                Image(systemName: "flag.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            
                            Button(action: { workoutManager.stopWorkout() }) {
                                Image(systemName: "stop.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            } else {
                // START SCREEN
                VStack(spacing: 16) {
                    Image(systemName: "figure.pool.swim")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                    
                    Text("SwiftLap")
                        .font(.title2.bold())
                    
                    Text("Pool: \(Int(workoutManager.poolLength))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: { workoutManager.startWorkout() }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Swim")
                        }
                        .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    
                    Button(action: { showingSettings = true }) {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Settings")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(poolLength: $workoutManager.poolLength)
                }
            }
        }
    }
    
    var fatigueColor: Color {
        switch workoutManager.fatigueLevel {
        case let level where level.contains("Fresh"): return .green
        case let level where level.contains("Moderate"): return .yellow
        case let level where level.contains("Tired"): return .orange
        default: return .red
        }
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .cyan
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline.bold())
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var poolLength: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Pool Length")
                .font(.headline)
            
            Picker("Pool", selection: $poolLength) {
                Text("25m").tag(25.0)
                Text("50m").tag(50.0)
            }
            .pickerStyle(.wheel)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
