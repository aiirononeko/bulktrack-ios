//import Foundation
//import Combine
//
//// APIService.swift などで定義されている WorkoutSetResponse をここで参照できるようにする必要がある
//// import するか、このファイル内に WorkoutSetResponse の定義を移動・コピーする
//// (ただし、モデル定義は一箇所にまとめるのが理想)
//// この例では、WorkoutSetResponse がグローバルにアクセス可能であると仮定しています。
//
//class SessionManager: ObservableObject {
//    var isSessionActive: Bool { 
//        return true // アプリがアクティブである限りセッション（的な区切り）は有効とみなす場合
//                    // もし「トレーニング中」フラグが別途必要なら、それを管理する
//    }
//
//    @Published var recordedSetsForCurrentSession: [String: [WorkoutSetResponse]] = [:]
//
//    private var cancellables = Set<AnyCancellable>()
//    private let userSettingsService = UserSettingsService.shared // UserSettingsServiceのインスタンスを保持
//
//    init() {
//        print("SessionManager initialized.")
//        // UserDefaultsから今日の記録を読み込む
//        self.recordedSetsForCurrentSession = userSettingsService.loadAllTodaysSets()
//        print("SessionManager: Loaded today's records. \(self.recordedSetsForCurrentSession.count) exercises have sets.")
//    }
//
//    // このメソッドはUIフローの区切りとして残すか、完全に削除するか検討。
//    // 今日の記録は自動的にロード・保存されるので、SessionManagerの状態リセットは不要。
//    func startNewWorkoutGrouping() {
//        DispatchQueue.main.async {
//            // self.recordedSetsForCurrentSession = [:] // 読み込みがあるので不要
//            print("SessionManager: startNewWorkoutGrouping called (today's data is auto-managed).")
//        }
//    }
//
//    // 同様に、このメソッドも役割が薄れる。
//    func endCurrentWorkoutGrouping() {
//        DispatchQueue.main.async {
//            // self.recordedSetsForCurrentSession = [:] // 今日の記録をクリアするわけではない
//            print("SessionManager: endCurrentWorkoutGrouping called (today's data is auto-managed).")
//        }
//    }
//
//    func getRecordedSets(for exerciseId: String) -> [WorkoutSetResponse] {
//        return recordedSetsForCurrentSession[exerciseId] ?? []
//    }
//
//    func addRecordedSet(_ setResponse: WorkoutSetResponse, for exerciseId: String) {
//        var setsForExercise = self.recordedSetsForCurrentSession[exerciseId] ?? []
//        setsForExercise.append(setResponse)
//        // setNumber でソートする場合 (APIレスポンスが順番を保証しない場合など)
//        // setsForExercise.sort { $0.setNumber < $1.setNumber }
//        self.recordedSetsForCurrentSession[exerciseId] = setsForExercise
//        userSettingsService.saveTodaysSets(for: exerciseId, sets: setsForExercise)
//        print("SessionManager: Added set for exercise \(exerciseId). Total sets now: \(setsForExercise.count). Saved to UserDefaults.")
//    }
//
//    func updateRecordedSet(_ updatedSetResponse: WorkoutSetResponse, for exerciseId: String) {
//        guard var setsForExercise = self.recordedSetsForCurrentSession[exerciseId],
//              let index = setsForExercise.firstIndex(where: { $0.id == updatedSetResponse.id }) else {
//            print("SessionManager: Could not find set with ID \(updatedSetResponse.id) for exercise \(exerciseId) to update.")
//            return
//        }
//        setsForExercise[index] = updatedSetResponse
//        // 必要であればソート
//        // setsForExercise.sort { $0.setNumber < $1.setNumber }
//        self.recordedSetsForCurrentSession[exerciseId] = setsForExercise
//        userSettingsService.saveTodaysSets(for: exerciseId, sets: setsForExercise)
//        print("SessionManager: Updated set ID \(updatedSetResponse.id) for exercise \(exerciseId). Saved to UserDefaults.")
//    }
//    
//    func deleteRecordedSet(setId: String, for exerciseId: String) {
//        guard var setsForExercise = self.recordedSetsForCurrentSession[exerciseId],
//              let index = setsForExercise.firstIndex(where: { $0.id == setId }) else {
//            print("SessionManager: Could not find set with ID \(setId) for exercise \(exerciseId) to delete.")
//            return
//        }
//        setsForExercise.remove(at: index)
//        if setsForExercise.isEmpty {
//            self.recordedSetsForCurrentSession.removeValue(forKey: exerciseId)
//            print("SessionManager: Removed last set for exercise \(exerciseId). Exercise key also removed from memory.")
//            userSettingsService.saveTodaysSets(for: exerciseId, sets: []) // 空配列を保存してUserDefaultsからも削除
//        } else {
//            self.recordedSetsForCurrentSession[exerciseId] = setsForExercise
//            // 必要であればソート
//            // setsForExercise.sort { $0.setNumber < $1.setNumber }
//            userSettingsService.saveTodaysSets(for: exerciseId, sets: setsForExercise)
//            print("SessionManager: Deleted set ID \(setId) for exercise \(exerciseId). Remaining sets: \(setsForExercise.count). Saved to UserDefaults.")
//        }
//    }
//
//    // このメソッドは、もはや「セッションデータ」というより「今日の全データ」クリアになる。
//    // 挙動を明確にするため、名前変更や削除を検討。
//    func clearAllTodaysData() { // メソッド名変更の提案
//        DispatchQueue.main.async {
//            let allKeys = self.recordedSetsForCurrentSession.keys
//            for exerciseId in allKeys {
//                // UserDefaultsから個別に削除 (saveTodaysSetsに空配列を渡すことで実現)
//                self.userSettingsService.saveTodaysSets(for: exerciseId, sets: [])
//            }
//            self.recordedSetsForCurrentSession = [:]
//            print("SessionManager: All today's data (recorded sets) cleared from memory and UserDefaults.")
//        }
//    }
//
//    // --- UserDefaults Persistence (Optional) ---
//    /*
//    private let sessionIdKey = "app.bulktrack.currentSessionId"
//
//    private func saveSessionToUserDefaults() {
//        UserDefaults.standard.set(currentSessionId, forKey: sessionIdKey)
//    }
//
//    private func loadSessionFromUserDefaults() {
//        if let savedSessionId = UserDefaults.standard.string(forKey: sessionIdKey) {
//            self.currentSessionId = savedSessionId
//            // self.isSessionActive = true (もし Published なら)
//            print("SessionManager: Loaded session from UserDefaults: \(savedSessionId)")
//        } else {
//            print("SessionManager: No session found in UserDefaults.")
//        }
//    }
//
//    private func clearSessionFromUserDefaults() {
//        UserDefaults.standard.removeObject(forKey: sessionIdKey)
//        print("SessionManager: Cleared session from UserDefaults.")
//    }
//    */
//}
