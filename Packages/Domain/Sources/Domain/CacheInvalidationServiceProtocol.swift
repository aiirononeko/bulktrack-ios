//
//  CacheInvalidationServiceProtocol.swift
//  Domain
//
//  Created by Ryota Katada on 2025/05/24.
//

import Foundation

public protocol CacheInvalidationServiceProtocol {
    /// 全種目キャッシュを無効化（カスタム種目作成時）
    func invalidateAllExercises() async
    
    /// 最近種目キャッシュを無効化（ワークアウト実行時）
    func invalidateRecentExercises() async
    
    /// 全キャッシュを無効化
    func invalidateAllCaches() async
}
