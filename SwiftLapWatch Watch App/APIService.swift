//
//  APIService.swift
//  SwiftLapWatch Watch App
//

import Foundation

struct WorkoutPayload: Codable {
    let swimmerId: String
    let duration: Int
    let distance: Double
    let laps: Int
    let strokeCount: Int
    let avgHeartRate: Double
    let calories: Double
    let lapTimes: [Double]
    let lapStrokes: [Int]
    let fatigueLevel: String
    let poolLength: Double
    let date: String
    let source: String
}

class APIService {
    
    // CHANGE THIS to your deployed SwiftLap URL
    static let baseURL = "https://swiftlap.onrender.com"
    
    // Send workout data to SwiftLap
    static func sendWorkout(_ payload: WorkoutPayload, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/watch/workout") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(false, "Failed to encode data")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
            if status == 200 {
                completion(true, nil)
            } else {
                completion(false, "HTTP \(status): \(body)")
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
    // Link watch using code from website
        static func linkWithCode(_ code: String, completion: @escaping (Bool, String?, String?) -> Void) {
            guard let url = URL(string: "\(baseURL)/api/watch/verify-code") else {
                completion(false, nil, "Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["code": code]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(false, nil, "Failed to encode")
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(false, nil, error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    completion(false, nil, "No data")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let swimmerId = json["swimmerId"] as? String {
                        completion(true, swimmerId, nil)
                    } else {
                        completion(false, nil, "Invalid code")
                    }
                } catch {
                    completion(false, nil, "Parse error")
                }
            }.resume()
        }
}
