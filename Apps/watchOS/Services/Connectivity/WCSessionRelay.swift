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

// MARK: - WatchConnectivity implementation

@MainActor
final class WCSessionRelay: NSObject, ObservableObject, SessionSyncRepository {

    // MARK: – Public Combine output
    private let recentSubject = PassthroughSubject<[ExerciseEntity], Error>()
    var recentExercisesPublisher: AnyPublisher<[ExerciseEntity], Error> {
        recentSubject.eraseToAnyPublisher()
    }

    private let session: WCSession

    // MARK: – Lifecycle
    override init() {
        self.session = WCSession.default
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
        guard let jsonString = reply["payload"] as? String,
              let data = jsonString.data(using: .utf8) else {
            recentSubject.send(completion: .failure(ConnectivityError.invalidPayload))
            return
        }
        do {
            let dtoList = try JSONDecoder().decode([ExerciseEntity].self, from: data)
            recentSubject.send(dtoList)
        } catch {
            recentSubject.send(completion: .failure(error))
        }
    }

    // MARK: – Errors
    enum ConnectivityError: LocalizedError {
        case notReachable
        case invalidPayload
        var errorDescription: String? {
            switch self {
            case .notReachable: return "iPhone と通信できません"
            case .invalidPayload: return "無効な返信フォーマット"
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
