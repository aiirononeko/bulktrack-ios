//
//  WCSessionRelay.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Combine
import WatchConnectivity
import Domain
import Data

// MARK: - WatchConnectivity implementation

@MainActor
final class WCSessionRelay: NSObject, ObservableObject, SessionSyncRepository {

    // MARK: – Public Combine output
    private let recentSubject = PassthroughSubject<[ExerciseEntity], Error>()
    var recentExercisesPublisher: AnyPublisher<[ExerciseEntity], Error> {
        recentSubject.eraseToAnyPublisher()
    }

    private let session: WCSession
    private let jsonDecoder: JSONDecoder

    // MARK: – Lifecycle
    override init() {
        self.session = WCSession.default
        self.jsonDecoder = JSONDecoder()
        // Configure decoder for date-time strings
        self.jsonDecoder.dateDecodingStrategy = .iso8601
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: – Reachability
    var isReachable: Bool { session.isReachable }

    // MARK: – Requests
    func requestRecentExercises(limit: Int = 20) {
        let payload: [String: Any] = ["type": "recentExercises", "limit": limit]
        guard session.isReachable else {
            recentSubject.send(completion: .failure(ConnectivityError.notReachable))
            return
        }
        session.sendMessage(payload, replyHandler: { [weak self] reply in
            self?.handleReply(reply)
        }, errorHandler: { [weak self] error in
            self?.recentSubject.send(completion: .failure(error))
        })
    }

    private func handleReply(_ reply: [String: Any]) {
        if let errorMessage = reply["wcsErrorMessage"] as? String {
            recentSubject.send(completion: .failure(ConnectivityError.remoteError(errorMessage)))
            return
        }
        
        guard let jsonString = reply["payload"] as? String,
              let data = jsonString.data(using: .utf8) else {
            recentSubject.send(completion: .failure(ConnectivityError.invalidPayload))
            return
        }
        do {
            let dtoList = try jsonDecoder.decode([ExerciseDTO].self, from: data)
            let entityList = PayloadMapper.mapToExerciseEntities(from: dtoList)
            recentSubject.send(entityList)
        } catch {
            // This catch block will handle DTO decoding errors or mapping errors if PayloadMapper throws.
            recentSubject.send(completion: .failure(ConnectivityError.processingError(error)))
        }
    }

    // MARK: – Errors
    enum ConnectivityError: LocalizedError {
        case notReachable
        case invalidPayload
        case remoteError(String) // Error message received from the counterpart device
        case processingError(Error) // Error during local processing of received data

        var errorDescription: String? {
            switch self {
            case .notReachable: return "iPhoneと通信できません。iPhoneでアプリが起動しているか確認してください。"
            case .invalidPayload: return "iPhoneからの応答が無効なフォーマットでした。"
            case .remoteError(let message): return "iPhone側でエラーが発生しました: \(message)"
            case .processingError(let error): return "受信データの処理中にエラーが発生しました: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - WCSessionDelegate (minimal)

extension WCSessionRelay: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation result if needed
        if let error { print("[WCSessionRelay] activation error: \(error)") }
    }

    // iPhone がフォアグラウンドで sendMessage を送れない場合、applicationContext で受け取る
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let json = applicationContext["allExercises"] as? String,
           let data = json.data(using: .utf8),
           let list = try? JSONDecoder().decode([ExerciseEntity].self, from: data) {
            // ここでは recent ではなく全種目リスト更新用 – 実装は後続タスク
            print("[WCSessionRelay] received allExercises context (\(list.count) items)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WCSessionRelay] reachability: \(session.isReachable)")
    }
}
