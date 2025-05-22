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
    private let handleRecentExercisesRequestUseCase: HandleRecentExercisesRequestUseCaseProtocol
    private let session = WCSession.default
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder // For potential future use if iOS needs to decode from watch

    // Updated initializer to accept HandleRecentExercisesRequestUseCaseProtocol
    init(handleRecentExercisesRequestUseCase: HandleRecentExercisesRequestUseCaseProtocol = DIContainer.shared.handleRecentExercisesRequestUseCase) {
        self.handleRecentExercisesRequestUseCase = handleRecentExercisesRequestUseCase
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
            replyHandler(["wcsErrorMessage": "無効なリクエストです (タイプ不明)"])
            return
        }

        print("WCSession (iOS) didReceiveMessage: \(message)")

        if type == "recentExercises" {
            guard let limit = message["limit"] as? Int else {
                replyHandler(["wcsErrorMessage": "無効なリクエストです (リミット不明)"])
                return
            }
            
            Task {
                do {
                    // UseCaseのexecuteメソッドはlocaleを内部で解決するため、引数として渡す必要はない
                    let entities = try await handleRecentExercisesRequestUseCase.execute(limit: limit)
                    let dtos = mapEntitiesToDTOs(entities) // DTOへのマッピングはWCSessionRelayの責務として残す
                    let responseData = try jsonEncoder.encode(dtos)
                    guard let jsonString = String(data: responseData, encoding: .utf8) else {
                        replyHandler(["wcsErrorMessage": "応答データの作成に失敗しました。"])
                        return
                    }
                    replyHandler(["payload": jsonString])
                } catch let error as LocalizedError {
                    replyHandler(["wcsErrorMessage": error.localizedDescription])
                } catch {
                    replyHandler(["wcsErrorMessage": "不明なサーバーエラーが発生しました。"])
                }
            }
        } else {
            replyHandler(["wcsErrorMessage": "不明なリクエストタイプです: \(type)"])
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
