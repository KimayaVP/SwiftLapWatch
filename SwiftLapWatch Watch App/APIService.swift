//
//  APIService.swift
//  SwiftLapWatch Watch App
//

import Foundation

class APIService {
    
    // CHANGE THIS to your deployed SwiftLap URL
    static let baseURL = "https://swiftlap.onrender.com"
    
    // Send workout data to SwiftLap
    static func sendWorkout(
        swimmerId: String,
        duration: Int,
        distance: Double,
        laps: Int,
        strokeCount: Int,
        avgHeartRate: Double,
        calories: Double,
        lapTimes: [Double],
        lapStrokes: [Int],
        fatigueLevel: String,
        poolLength: Double,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/watch/workout") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let workoutData: [String: Any] = [
            "swimmerId": swimmerId,
            "duration": duration,
            "distance": distance,
            "laps": laps,
            "strokeCount": strokeCount,
            "avgHeartRate": avgHeartRate,
            "calories": calories,
            "lapTimes": lapTimes,
            "lapStrokes": lapStrokes,
            "fatigueLevel": fatigueLevel,
            "poolLength": poolLength,
            "date": ISO8601DateFormatter().string(from: Date()),
            "source": "apple_watch"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: workoutData)
        } catch {
            completion(false, "Failed to encode data")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                completion(false, "Server error")
            }
        }.resume()
    }
    
    // Get swimmer ID from stored credentials
    static func getStoredSwimmerId() -> String? {
        return UserDefaults.standard.string(forKey: "swimmerId")
    }
    
    // Store swimmer ID after login
    static func storeSwimmerId(_ id: String) {
        UserDefaults.standard.set(id, forKey: "swimmerId")
    }
}
