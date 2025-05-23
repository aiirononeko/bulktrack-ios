//
//  SetCreateDTO.swift
//  Data
//
//  Created by Ryota Katada on 2025/05/23.
//

import Foundation

public struct SetCreateDTO: Codable {
    public let exerciseId: UUID
    public let weight: Double
    public let reps: Int
    public let rpe: Double?
    public let notes: String?
    public let performedAt: Date

    // CodingKeys はカスタムエンコードロジックで不要になる場合があるが、
    // デフォルトのデコード処理や他のプロパティのために残しておいても良い。
    // ここでは明示的に全てのキーを扱っているため、enum CodingKeys は必須ではない。

    public init(
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        notes: String? = nil,
        performedAt: Date
    ) {
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.performedAt = performedAt
    }

    // カスタムエンコード処理を追加して exerciseId を小文字にする
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exerciseId.uuidString.lowercased(), forKey: .exerciseId)
        try container.encode(weight, forKey: .weight)
        try container.encode(reps, forKey: .reps)
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(performedAt, forKey: .performedAt)
    }

    // CodingKeys をカスタムエンコードで使用するために定義しておく
    // もし init でしか使わないなら、encode 内で文字列キーを直接指定しても良い
    enum CodingKeys: String, CodingKey {
        case exerciseId
        case weight
        case reps
        case rpe
        case notes
        case performedAt
    }
}
