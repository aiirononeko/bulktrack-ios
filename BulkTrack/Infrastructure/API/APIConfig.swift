//
//  APIConfig.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import Foundation

enum APIConfig {
    static var baseURL: String = {
        guard let rawURLString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseURL") as? String else {
            // .xcconfigまたはInfo.plistの設定ミスが考えられるため、クラッシュさせて早期に気づけるようにする
            fatalError("ApiBaseURL not set in Info.plist or .xcconfig is missing/incorrect.")
        }
        // xcconfig由来の \/ を / に置換する
        var urlString = rawURLString.replacingOccurrences(of: "\\/", with: "/")

        // URLの末尾のスラッシュを統一（あれば削除し、なければそのまま）
        if urlString.hasSuffix("/") {
            urlString = String(urlString.dropLast())
        }
        return urlString
    }()

    // 例: 特定のエンドポイントへのURLを生成するヘルパー
    // static func endpoint(_ path: String) -> String {
    //     return baseURL + "/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    // }
}
