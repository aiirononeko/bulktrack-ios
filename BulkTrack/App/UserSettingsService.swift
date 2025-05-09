import Foundation

// 個々のセットの詳細
struct RecordedSetDetail: Codable, Identifiable {
    var id = UUID() // Identifiable 準拠のため (List表示用)
    let setNumber: Int
    let weight: Float
    let reps: Int
    let rpe: Float?

    // WorkoutSetResponseから変換するためのイニシャライザ
    init(from setResponse: WorkoutSetResponse) {
        self.setNumber = setResponse.setNo
        self.weight = setResponse.weight
        self.reps = setResponse.reps
        self.rpe = setResponse.rpe
    }
    
    // 表示用の文字列 (オプション)
    var displayString: String {
        var details = "Set \(setNumber): \(String(format: "%.1f", weight))kg x \(reps) reps"
        if let rpeValue = rpe {
            details += " RPE \(String(format: "%.1f", rpeValue))"
        }
        return details
    }
}

// 特定の種目に対する、直近のワークアウトセッションの全セット記録
struct LastWorkoutSessionForExercise: Codable, Identifiable {
    let exerciseId: String
    let sessionId: String // この記録がどのセッションのものだったか
    let recordedDate: Date
    let sets: [RecordedSetDetail]

    // Identifiableのためのid。exerciseIdとsessionIdの組み合わせでユニークにする
    var id: String { exerciseId + "_" + sessionId }
}

class UserSettingsService {
    static let shared = UserSettingsService()
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        // Date型のエンコード/デコード戦略を設定 (ISO8601が一般的で堅牢)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    private func exerciseRecordKey(for exerciseId: String) -> String {
        // キー名にプレフィックスをつけて、他のUserDefaultsのキーと区別しやすくする
        return "lastWorkoutSession_for_exercise_\(exerciseId)"
    }

    // 直近のワークアウト記録を保存
    func saveLastWorkoutSession(for exercise: Exercise, with sessionId: String, setsFromCurrentSession: [WorkoutSetResponse]) {
        guard !setsFromCurrentSession.isEmpty else {
            // セットが空の場合は古い記録を削除するか、何もしないか。
            // 今回は、セットが記録された時に「その時点での全セット」を保存するので、
            // 空のセット配列で上書きすることは、実質的に記録削除と同じ意味になる場合がある。
            // 要件に応じて、setsFromCurrentSessionが空なら何もしない、または明示的に削除する。
            // ここでは、空なら記録を削除する（または何もしないで古い記録を残す）方針も考えられる。
            // 一旦、空のセットが来たらその種目の記録を削除する方針にしてみる。
            print("UserSettingsService: No sets provided for exercise \(exercise.id) in session \(sessionId). Deleting any existing record.")
            deleteLastWorkoutSession(for: exercise.id)
            return
        }

        let setDetails = setsFromCurrentSession.map { RecordedSetDetail(from: $0) }
        
        let lastSessionRecord = LastWorkoutSessionForExercise(
            exerciseId: exercise.id,
            sessionId: sessionId, // 現在のセッションIDを保存
            recordedDate: Date(), // 現在日時を保存
            sets: setDetails
        )

        do {
            let data = try encoder.encode(lastSessionRecord)
            userDefaults.set(data, forKey: exerciseRecordKey(for: exercise.id))
            print("UserSettingsService: Saved last workout session (ID: \(sessionId)) for exercise \(exercise.id) with \(setDetails.count) sets.")
        } catch {
            print("UserSettingsService: Failed to encode/save LastWorkoutSession for \(exercise.id): \(error.localizedDescription)")
        }
    }

    // 直近のワークアウト記録を読み込み
    func getLastWorkoutSession(for exerciseId: String, excludingCurrentSessionId: String?) -> LastWorkoutSessionForExercise? {
        guard let data = userDefaults.data(forKey: exerciseRecordKey(for: exerciseId)) else {
            print("UserSettingsService: No saved data found for exercise \(exerciseId).")
            return nil
        }
        do {
            let record = try decoder.decode(LastWorkoutSessionForExercise.self, from: data)
            
            // 現在のセッションIDと異なる場合のみ返す
            if let currentSid = excludingCurrentSessionId, record.sessionId == currentSid {
                print("UserSettingsService: Loaded record for exercise \(exerciseId) belongs to the current session (\(currentSid)). Not treating as 'last' workout.")
                return nil
            }
            
            print("UserSettingsService: Loaded last workout session (ID: \(record.sessionId)) for exercise \(exerciseId) with \(record.sets.count) sets, recorded on \(record.recordedDate).")
            return record
        } catch {
            print("UserSettingsService: Failed to decode LastWorkoutSession for \(exerciseId): \(error.localizedDescription)")
            // デコード失敗時は古い不正なデータを削除するのも一案
            // userDefaults.removeObject(forKey: exerciseRecordKey(for: exerciseId))
            return nil
        }
    }

    // 特定の種目の記録を削除 (オプション)
    func deleteLastWorkoutSession(for exerciseId: String) {
        userDefaults.removeObject(forKey: exerciseRecordKey(for: exerciseId))
        print("UserSettingsService: Deleted last workout session for exercise \(exerciseId).")
    }
}

// WorkoutSetResponse がこのファイルから参照できない場合は、
// APIService.swiftからimportするか、ここで仮定義またはAPIServiceのモデル定義ファイルへの参照が必要。
// 例: (APIService.swift にある WorkoutSetResponse を想定)
// struct WorkoutSetResponse { ... }
