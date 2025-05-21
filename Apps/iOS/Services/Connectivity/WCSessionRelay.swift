//
//  WCSessionRelay.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

// Apps/iOS/Services/Connectivity/WCSessionRelay.swift
import Foundation
import WatchConnectivity
import Combine
import Domain
import Data

@MainActor
final class WCSessionRelay: NSObject, ObservableObject {
    private let api = APIService()
    private let session = WCSession.default

    // Combine 出力
    private let recentSubject = PassthroughSubject<[ExerciseEntity], Error>()
}

// MARK: - SessionSyncRepository conformance
extension WCSessionRelay: SessionSyncRepository {
    var isReachable: Bool { session.isReachable }

    var recentExercisesPublisher: AnyPublisher<[ExerciseEntity], Error> {
        recentSubject.eraseToAnyPublisher()
    }

    func requestRecentExercises(limit: Int) {
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

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }
}

// MARK: - WCSessionDelegate
extension WCSessionRelay: WCSessionDelegate {
    /* 既存の delegate 実装をそのまま残す */
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) { /* … */ }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) { /* … */ }

    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}

// MARK: - Helpers
private extension WCSessionRelay {
    enum ConnectivityError: Error { case notReachable }

    func handleReply(_ reply: [String: Any]) {
        guard let json = reply["payload"] as? String,
              let data = json.data(using: .utf8) else { return }
        if let list = try? JSONDecoder().decode([ExerciseEntity].self, from: data) {
            recentSubject.send(list)
        }
    }
}
