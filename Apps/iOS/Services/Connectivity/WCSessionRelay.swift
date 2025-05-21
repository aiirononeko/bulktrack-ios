//
//  WCSessionRelay.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

//import Foundation
//import WatchConnectivity
//import Data
//import Domain
//
//@MainActor
//final class WCSessionRelay: NSObject, ObservableObject {
//    private let api = APIService()   // conforms to ExerciseRepository
//    private let session = WCSession.default
//
//    override init() {
//        super.init()
//        guard WCSession.isSupported() else { return }
//        session.delegate = self
//        session.activate()
//    }
//}
//
//// MARK: - WCSessionDelegate
//extension WCSessionRelay: WCSessionDelegate {
//    func session(_ session: WCSession,
//                 activationDidCompleteWith state: WCSessionActivationState,
//                 error: Error?) {
//        print("[iOS] WCSession activation:", state, error ?? "no-error")
//    }
//
//    func session(_ session: WCSession,
//                 didReceiveMessage message: [String : Any],
//                 replyHandler: @escaping ([String : Any]) -> Void) {
//
//        guard message["type"] as? String == "recentExercises" else { return }
//
//        let limit = message["limit"] as? Int ?? 20
//        Task {
//            do {
//                let list = try await api.recentExercises(limit: limit,
//                                                         offset: 0,
//                                                         locale: "ja")
//                let data = try JSONEncoder().encode(list)
//                replyHandler([
//                    "payload": String(decoding: data, as: UTF8.self)
//                ])
//            } catch {
//                replyHandler(["error": error.localizedDescription])
//            }
//        }
//    }
//
//    // 省略: 背景送信（applicationContext など）が必要になったら実装
//}
