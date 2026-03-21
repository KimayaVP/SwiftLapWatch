//
//  WorkoutManager.swift
//  SwiftLapWatch Watch App
//
//  Created by Kimaya on 20/03/26.
//

import Foundation
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties (UI updates)
    @Published var isWorkoutActive = false
    @Published var elapsedSeconds: Int = 0
    @Published var heartRate: Double = 0
    @Published var strokeCount: Int = 0
    @Published var lapCount: Int = 0
    @Published var distance: Double = 0 // in meters
    @Published var calories: Double = 0
    @Published var fatigueLevel: String = "Fresh 💪"
    @Published var currentPace: String = "--:--"
    @Published var avgStrokesPerLap: Double = 0
    
    // MARK: - Workout Data
    var poolLength: Double = 25 // meters
    private var workoutStartTime: Date?
    private var lapTimes: [Double] = []
    private var lapStrokes: [Int] = []
    private var heartRates: [Double] = []
    
    // MARK: - HealthKit
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
            #if targetEnvironment(simulator)
            print("Running in simulator - HealthKit limited")
            return
            #else
            let typesToShare: Set = [
                HKQuantityType.workoutType()
            ]
            
            let typesToRead: Set = [
                HKQuantityType(.heartRate),
                HKQuantityType(.activeEnergyBurned),
                HKQuantityType(.swimmingStrokeCount),
                HKQuantityType(.distanceSwimming)
            ]
            
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if !success {
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            #endif
        }
    
    // MARK: - Start Workout
    // MARK: - Start Workout
        func startWorkout() {
            #if targetEnvironment(simulator)
            // Simulator mode - just start timer
            DispatchQueue.main.async {
                self.isWorkoutActive = true
                self.workoutStartTime = Date()
                self.startTimer()
            }
            return
            #else
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .swimming
            configuration.locationType = .indoor
            configuration.swimmingLocationType = .pool
            configuration.lapLength = HKQuantity(unit: .meter(), doubleValue: poolLength)
            
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                workoutBuilder = workoutSession?.associatedWorkoutBuilder()
                
                workoutSession?.delegate = self
                workoutBuilder?.delegate = self
                workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
                
                let startDate = Date()
                workoutSession?.startActivity(with: startDate)
                workoutBuilder?.beginCollection(withStart: startDate) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            self.isWorkoutActive = true
                            self.workoutStartTime = startDate
                            self.startTimer()
                        }
                    }
                }
            } catch {
                print("Failed to start workout: \(error.localizedDescription)")
            }
            #endif
        }
    
    // MARK: - Stop Workout
    // MARK: - Stop Workout
        func stopWorkout() {
            #if targetEnvironment(simulator)
            DispatchQueue.main.async {
                self.isWorkoutActive = false
                self.stopTimer()
                self.saveWorkoutToSwiftLap()
            }
            return
            #else
            workoutSession?.end()
            
            workoutBuilder?.endCollection(withEnd: Date()) { success, error in
                if success {
                    self.workoutBuilder?.finishWorkout { workout, error in
                        DispatchQueue.main.async {
                            self.isWorkoutActive = false
                            self.stopTimer()
                            self.saveWorkoutToSwiftLap()
                        }
                    }
                }
            }
            #endif
        }
    
    // MARK: - Mark Lap
    // MARK: - Mark Lap
        func markLap() {
            let lapTime = Double(elapsedSeconds) - lapTimes.reduce(0, +)
            lapTimes.append(lapTime)
            lapStrokes.append(strokeCount - lapStrokes.reduce(0, +))
            lapCount += 1
            distance = Double(lapCount) * poolLength
            
            #if targetEnvironment(simulator)
            // Simulate some data for testing
            heartRate = Double.random(in: 120...160)
            heartRates.append(heartRate)
            strokeCount += Int.random(in: 14...20)
            #endif
            
            updatePace()
            updateFatigue()
        }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.elapsedSeconds += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Pace Calculation
    private func updatePace() {
        if lapCount > 0 && elapsedSeconds > 0 {
            let avgSecondsPerLap = Double(elapsedSeconds) / Double(lapCount)
            let minutes = Int(avgSecondsPerLap) / 60
            let seconds = Int(avgSecondsPerLap) % 60
            currentPace = String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Fatigue Calculation
    // MARK: - Fatigue Calculation
        private func updateFatigue() {
            // Show fatigue even with 1 lap for demo
            guard lapTimes.count >= 1 else { return }
            
            var fatigueScore = 0.0
            
            if lapTimes.count >= 2 {
                let recentLaps = lapTimes.suffix(3)
                let firstLaps = lapTimes.prefix(3)
                
                let recentAvg = recentLaps.reduce(0, +) / Double(recentLaps.count)
                let firstAvg = firstLaps.reduce(0, +) / Double(firstLaps.count)
                
                fatigueScore = ((recentAvg - firstAvg) / firstAvg) * 100
            }
            
            // Factor in heart rate
            if heartRates.count >= 2 {
                let recentHR = heartRates.suffix(5).reduce(0, +) / Double(min(5, heartRates.count))
                let startHR = heartRates.prefix(5).reduce(0, +) / Double(min(5, heartRates.count))
                let hrFactor = ((recentHR - startHR) / max(startHR, 1)) * 100
                fatigueScore += (hrFactor * 0.5)
            }
            
            DispatchQueue.main.async {
                if self.lapCount <= 2 {
                    self.fatigueLevel = "Fresh 💪"
                } else if fatigueScore < 5 {
                    self.fatigueLevel = "Fresh 💪"
                } else if fatigueScore < 10 {
                    self.fatigueLevel = "Moderate 😊"
                } else if fatigueScore < 18 {
                    self.fatigueLevel = "Tired 😓"
                } else {
                    self.fatigueLevel = "Exhausted 🥵"
                }
            }
        }
    // MARK: - Save to SwiftLap
    // MARK: - Save to SwiftLap
        private func saveWorkoutToSwiftLap() {
            guard let swimmerId = APIService.getStoredSwimmerId() else {
                print("No swimmer ID stored - workout saved locally only")
                return
            }
            
            let avgHR = heartRates.isEmpty ? 0.0 : heartRates.reduce(0, +) / Double(heartRates.count)
            
            APIService.sendWorkout(
                swimmerId: swimmerId,
                duration: elapsedSeconds,
                distance: distance,
                laps: lapCount,
                strokeCount: strokeCount,
                avgHeartRate: avgHR,
                calories: calories,
                lapTimes: lapTimes,
                lapStrokes: lapStrokes,
                fatigueLevel: fatigueLevel,
                poolLength: poolLength
            ) { success, error in
                if success {
                    print("Workout synced to SwiftLap!")
                } else {
                    print("Failed to sync: \(error ?? "Unknown error")")
                }
            }
        }
    // MARK: - Format Time
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle state changes
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType(.heartRate):
                    let hr = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                    self.heartRate = hr
                    self.heartRates.append(hr)
                    
                case HKQuantityType(.swimmingStrokeCount):
                    self.strokeCount = Int(statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    
                case HKQuantityType(.activeEnergyBurned):
                    self.calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    
                case HKQuantityType(.distanceSwimming):
                    let dist = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    if dist > self.distance {
                        self.distance = dist
                        self.lapCount = Int(dist / self.poolLength)
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
}
