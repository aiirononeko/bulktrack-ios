//
//  WCSessionRelay.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

// Apps/iOS/Services/Connectivity/WCSessionRelay.swift
import Foundation
import WatchConnectivity
import Domain // For ExerciseEntity
import Data   // For ExerciseDTO and APIService

@MainActor
final class WCSessionRelay: NSObject, ObservableObject {
    // TODO: Inject APIService via DIContainer
    private let apiService = APIService()
    private let session = WCSession.default
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder // For potential future use if iOS needs to decode from watch

    override init() {
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
}

// MARK: - WCSessionDelegate
extension WCSessionRelay: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("WCSession (iOS) activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession (iOS) activated with state: \(state.rawValue)")
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        
        guard let type = message["type"] as? String else {
            print("WCSession (iOS) didReceiveMessage: Missing 'type' in message: \(message)")
            replyHandler(["error": "Missing 'type' in message"])
            return
        }

        print("WCSession (iOS) didReceiveMessage: \(message)")

        if type == "recentExercises" {
            guard let limit = message["limit"] as? Int else {
                replyHandler(["error": "Missing 'limit' for recentExercises"])
                return
            }
            
            Task {
                do {
                    // APIService.recentExercises returns [ExerciseEntity]
                    // We need to send [ExerciseDTO] to the watch.
                    // For now, APIService returns mock ExerciseEntity data.
                    // Let's assume locale is not strictly needed for mock or can be defaulted.
                    let entities = try await apiService.recentExercises(limit: limit, offset: 0, locale: "en") // Locale can be passed or defaulted
                    
                    // Map [ExerciseEntity] to [ExerciseDTO]
                    let dtos = mapEntitiesToDTOs(entities)
                    
                    let responseData = try jsonEncoder.encode(dtos)
                    guard let jsonString = String(data: responseData, encoding: .utf8) else {
                        replyHandler(["error": "Failed to create JSON string from DTOs"])
                        return
                    }
                    replyHandler(["payload": jsonString])
                } catch {
                    replyHandler(["error": error.localizedDescription])
                }
            }
        } else {
            replyHandler(["error": "Unknown message type: \(type)"])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
        print("WCSession (iOS) did become inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate the session as a new session is needed.
        print("WCSession (iOS) did deactivate, reactivating...")
        session.activate()
    }
}

// MARK: - Helpers (Entity to DTO Mapping)
// This mapping should ideally be in a shared or iOS-specific mapper.
// For now, placing it here for simplicity.
private extension WCSessionRelay {
    
    private static let iso8601FormatterForDecoding: ISO8601DateFormatter = { // For parsing ISODate (String)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func mapEntitiesToDTOs(_ entities: [ExerciseEntity]) -> [ExerciseDTO] {
        entities.map { entity in
            let lastUsedAtDate: Date?
            if let isoDateString = entity.lastUsedAt { // entity.lastUsedAt is ISODate (String)
                lastUsedAtDate = WCSessionRelay.iso8601FormatterForDecoding.date(from: isoDateString)
            } else {
                lastUsedAtDate = nil
            }
            
            return ExerciseDTO(
                id: entity.id,
                name: entity.name,
                isOfficial: entity.isOfficial ?? false, // DTO is Bool, Entity is Bool?. Default to false if nil.
                lastUsedAt: lastUsedAtDate,
                useCount: entity.useCount
            )
        }
    }
}
