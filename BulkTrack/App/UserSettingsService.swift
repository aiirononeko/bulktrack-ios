//import Foundation
//
//// 個々のセットの詳細
//struct RecordedSetDetail: Codable, Identifiable {
//    var id = UUID() // Identifiable 準拠のため (List表示用)
//    let setNumber: Int
//    let weight: Float
//    let reps: Int
//    let rpe: Float?
//
//    // WorkoutSetResponseから変換するためのイニシャライザ
//    init(from setResponse: WorkoutSetResponse) {
//        self.setNumber = setResponse.setNumber
//        self.weight = setResponse.weight
//        self.reps = setResponse.reps
//        self.rpe = setResponse.rpe
//    }
//    
//    // 表示用の文字列 (オプション)
//    var displayString: String {
//        var details = "Set \(setNumber): \(String(format: "%.1f", weight))kg x \(reps) reps"
//        if let rpeValue = rpe {
//            details += " RPE \(String(format: "%.1f", rpeValue))"
//        }
//        return details
//    }
//}
//
//// 特定の種目に対する、直近のワークアウトセッションの全セット記録
//struct LastWorkoutSessionForExercise: Codable, Identifiable {
//    let exerciseId: String
//    let sessionId: String // この記録がどのセッションのものだったか
//    let recordedDate: Date
//    let sets: [RecordedSetDetail]
//
//    // Identifiableのためのid。exerciseIdとsessionIdの組み合わせでユニークにする
//    var id: String { exerciseId + "_" + sessionId }
//}
//
//class UserSettingsService {
//    static let shared = UserSettingsService()
//    private let userDefaults = UserDefaults.standard
//    private let encoder = JSONEncoder()
//    private let decoder = JSONDecoder()
//
//    private init() {
//        // Date型のエンコード/デコード戦略を設定 (ISO8601が一般的で堅牢)
//        encoder.dateEncodingStrategy = .iso8601
//        decoder.dateDecodingStrategy = .iso8601
//    }
//
//    private func exerciseRecordKey(for exerciseId: String) -> String {
//        // キー名にプレフィックスをつけて、他のUserDefaultsのキーと区別しやすくする
//        return "lastWorkoutSession_for_exercise_\(exerciseId)"
//    }
//
//    private func dailyRecordKey(for exerciseId: String, date: Date) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let dateString = dateFormatter.string(from: date)
//        // キーに WorkoutSetResponse であることを明示する（RecordedSetDetailと区別するため）
//        return "dailyWorkoutSetResponses_\(dateString)_for_exercise_\(exerciseId)"
//    }
//
//    // 直近のワークアウト記録を保存
//    func saveLastWorkoutSession(for exercise: Exercise, with sessionId: String, setsFromCurrentSession: [WorkoutSetResponse]) {
//        guard !setsFromCurrentSession.isEmpty else {
//            // セットが空の場合は古い記録を削除するか、何もしないか。
//            // 今回は、セットが記録された時に「その時点での全セット」を保存するので、
//            // 空のセット配列で上書きすることは、実質的に記録削除と同じ意味になる場合がある。
//            // 要件に応じて、setsFromCurrentSessionが空なら何もしない、または明示的に削除する。
//            // ここでは、空なら記録を削除する（または何もしないで古い記録を残す）方針も考えられる。
//            // 一旦、空のセットが来たらその種目の記録を削除する方針にしてみる。
//            print("UserSettingsService: No sets provided for exercise \(exercise.id) in session \(sessionId). Deleting any existing record.")
//            deleteLastWorkoutSession(for: exercise.id)
//            return
//        }
//
//        let setDetails = setsFromCurrentSession.map { RecordedSetDetail(from: $0) }
//        
//        let lastSessionRecord = LastWorkoutSessionForExercise(
//            exerciseId: exercise.id,
//            sessionId: sessionId, // 現在のセッションIDを保存
//            recordedDate: Date(), // 現在日時を保存
//            sets: setDetails
//        )
//
//        do {
//            let data = try encoder.encode(lastSessionRecord)
//            userDefaults.set(data, forKey: exerciseRecordKey(for: exercise.id))
//            print("UserSettingsService: Saved last workout session (ID: \(sessionId)) for exercise \(exercise.id) with \(setDetails.count) sets.")
//            
//            // Watchへ最新情報を送信
//            WatchDataRelayService.shared.sendRecentWorkoutsToWatch()
//        } catch {
//            print("UserSettingsService: Failed to encode/save LastWorkoutSession for \(exercise.id): \(error.localizedDescription)")
//        }
//    }
//
//    // 直近のワークアウト記録を読み込み
//    func getLastWorkoutSession(for exerciseId: String, excludingCurrentSessionId: String?) -> LastWorkoutSessionForExercise? {
//        let allSessions = getAllLastWorkoutSessions()
//        
//        let calendar = Calendar.current
//        let todayStart = calendar.startOfDay(for: Date())
//
//        let relevantSessions = allSessions
//            .filter { $0.exerciseId == exerciseId }
//            .filter { sessionRecord -> Bool in
//                // excludingCurrentSessionId があれば、それと一致するものは除外
//                if let currentSid = excludingCurrentSessionId, sessionRecord.sessionId == currentSid {
//                    return false
//                }
//                return true
//            }
//            .filter { sessionRecord -> Bool in
//                // recordedDate が「昨日より前」であるか
//                return sessionRecord.recordedDate < todayStart
//            }
//            .sorted { $0.recordedDate > $1.recordedDate } // 新しい順にソート
//
//        guard let latestRelevantSession = relevantSessions.first else {
//            print("UserSettingsService: No relevant sessions found from yesterday or earlier for exercise \(exerciseId).")
//            return nil
//        }
//
//        let targetDateStart = calendar.startOfDay(for: latestRelevantSession.recordedDate)
//        
//        // targetDateStart と同じ日付のセッションのセットをすべて収集
//        var combinedSets: [RecordedSetDetail] = []
//        var representativeSessionId = latestRelevantSession.sessionId // 代表のセッションID（最初のもの）
//        
//        for session in relevantSessions {
//            if calendar.isDate(session.recordedDate, inSameDayAs: targetDateStart) {
//                combinedSets.append(contentsOf: session.sets)
//            }
//        }
//        
//        // セットをsetNumberでソートする (任意だが、表示順序が安定する)
//        combinedSets.sort { $0.setNumber < $1.setNumber }
//
//        if combinedSets.isEmpty {
//            print("UserSettingsService: No sets found on the target date (\(targetDateStart)) for exercise \(exerciseId), though a session existed.")
//            return nil
//        }
//
//        print("UserSettingsService: Found \(combinedSets.count) sets for exercise \(exerciseId) on \(targetDateStart) (from session(s) like \(representativeSessionId)).")
//        
//        // 新しい LastWorkoutSessionForExercise を合成して返す
//        // sessionId は代表のものか、あるいは固定の文字列でも良い
//        return LastWorkoutSessionForExercise(
//            exerciseId: exerciseId,
//            sessionId: representativeSessionId, // または "last-day-composite-\(exerciseId)" など
//            recordedDate: targetDateStart, // 日付の開始時刻を代表として使用
//            sets: combinedSets
//        )
//    }
//
//    // 特定の種目の記録を削除 (オプション)
//    func deleteLastWorkoutSession(for exerciseId: String) {
//        userDefaults.removeObject(forKey: exerciseRecordKey(for: exerciseId))
//        print("UserSettingsService: Deleted last workout session for exercise \(exerciseId).")
//    }
//
//    // UserDefaultsに保存されている全てのLastWorkoutSessionForExerciseを取得する
//    func getAllLastWorkoutSessions() -> [LastWorkoutSessionForExercise] {
//        var allSessions: [LastWorkoutSessionForExercise] = []
//        let dictionary = userDefaults.dictionaryRepresentation()
//        
//        for (key, value) in dictionary {
//            if key.hasPrefix("lastWorkoutSession_for_exercise_") {
//                if let data = value as? Data {
//                    do {
//                        let session = try decoder.decode(LastWorkoutSessionForExercise.self, from: data)
//                        allSessions.append(session)
//                    } catch {
//                        print("UserSettingsService: Failed to decode LastWorkoutSessionForExercise for key \(key): \(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//        return allSessions
//    }
//
//    func saveTodaysSets(for exerciseId: String, sets: [WorkoutSetResponse]) {
//        // let setDetails = sets.map { RecordedSetDetail(from: $0) } // WorkoutSetResponseを直接保存
//        let today = Date()
//        let key = dailyRecordKey(for: exerciseId, date: today)
//
//        if sets.isEmpty {
//            userDefaults.removeObject(forKey: key)
//            print("UserSettingsService: Removed today's sets (WorkoutSetResponse) for exercise \(exerciseId) as the list was empty.")
//            return
//        }
//
//        do {
//            let data = try encoder.encode(sets) // WorkoutSetResponseの配列をエンコード
//            userDefaults.set(data, forKey: key)
//            print("UserSettingsService: Saved \(sets.count) sets (WorkoutSetResponse) for today for exercise \(exerciseId).")
//        } catch {
//            print("UserSettingsService: Failed to encode/save today's sets (WorkoutSetResponse) for \(exerciseId): \(error.localizedDescription)")
//        }
//    }
//
//    func loadTodaysSets(for exerciseId: String) -> [WorkoutSetResponse]? {
//        let today = Date()
//        let key = dailyRecordKey(for: exerciseId, date: today)
//        guard let data = userDefaults.data(forKey: key) else {
//            return nil
//        }
//        do {
//            let setResponses = try decoder.decode([WorkoutSetResponse].self, from: data) // WorkoutSetResponseの配列をデコード
//            print("UserSettingsService: Loaded \(setResponses.count) sets (WorkoutSetResponse) for today for exercise \(exerciseId).")
//            return setResponses
//        } catch {
//            print("UserSettingsService: Failed to decode today's sets (WorkoutSetResponse) for \(exerciseId): \(error.localizedDescription)")
//            return nil
//        }
//    }
//    
//    func loadAllTodaysSets() -> [String: [WorkoutSetResponse]] {
//        var allTodaysRecords: [String: [WorkoutSetResponse]] = [:]
//        let dictionary = userDefaults.dictionaryRepresentation()
//        let today = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let todayDateString = dateFormatter.string(from: today)
//        
//        let prefixPattern = "dailyWorkoutSetResponses_\(todayDateString)_for_exercise_" // キープレフィックスを修正
//
//        for (key, value) in dictionary {
//            if key.hasPrefix(prefixPattern) {
//                if let data = value as? Data {
//                    let exerciseId = String(key.dropFirst(prefixPattern.count))
//                    do {
//                        let setResponses = try decoder.decode([WorkoutSetResponse].self, from: data) // WorkoutSetResponseの配列をデコード
//                        allTodaysRecords[exerciseId] = setResponses
//                        // print("UserSettingsService: Loaded \(setResponses.count) sets (WSR) for today for ex \(exerciseId) from all.") // ログ簡略化
//                    } catch {
//                        print("UserSettingsService: Failed to decode today's WSR sets for key \(key) in loadAllTodaysSets: \(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//        print("UserSettingsService: Loaded all today's records (WorkoutSetResponse). Found \(allTodaysRecords.count) exercises with sets.")
//        return allTodaysRecords
//    }
//}
//
//// WorkoutSetResponse がこのファイルから参照できない場合は、
//// APIService.swiftからimportするか、ここで仮定義またはAPIServiceのモデル定義ファイルへの参照が必要。
//// 例: (APIService.swift にある WorkoutSetResponse を想定)
//// struct WorkoutSetResponse { ... }
