//
//  RepositoryProtocols.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import Combine

public protocol SessionSyncRepository {
    /// iPhone との到達可能性
    var isReachable: Bool { get }

    /// iPhone から push される「最近種目」のストリーム
    var recentExercisesPublisher: AnyPublisher<[ExerciseEntity], Error> { get }

    /// iPhone に対して「最近種目を送って」と依頼
    func requestRecentExercises(limit: Int)

    /// WCSession.activate() 相当。App 起動時に 1 回呼び出す
    func activate()
}

public protocol ExerciseRepository {
    /// クエリ検索（検索語が nil なら全件）
    func searchExercises(query: String?, locale: String?) async throws -> [ExerciseEntity]

    /// 最近使った種目を取得
    func recentExercises(limit: Int, offset: Int, locale: String) async throws -> [ExerciseEntity]
}
