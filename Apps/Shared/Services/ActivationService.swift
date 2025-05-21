//
//  ActivationService.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation

public protocol ActivationServiceProtocol {
    /// デバイスが未アクティベートならアクティベートする
    func activateDeviceIfNeeded() async throws
}

/// 実サービスが入るまでのダミー実装
public final class ActivationService: ActivationServiceProtocol {

    /// 未アクティベートならサーバーへ登録する想定（今は成功返し）
    public func activateDeviceIfNeeded() async throws {
        // TODO: REST 呼び出しを実装
        print("[ActivationService] dummy activate")
    }
}
