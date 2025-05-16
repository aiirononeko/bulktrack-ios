import Foundation
import WatchConnectivity

// Watchアプリと共有するデータ構造 (Watch側のWorkoutDataと一致させる)
struct WatchWorkoutData: Identifiable, Codable {
    let id: String // exerciseId
    let name: String
    // let lastPerformedDate: Date? // 必要に応じて追加
}

// Watchから受信するセット情報の構造体 (Watch側のWorkoutSetInfoと一致させる)
struct ReceivedWorkoutSetInfo: Codable {
    // let id: UUID // UUIDはデコード時に問題になることがあるので、必要ならStringに
    let weight: Double
    let reps: Int
    let rpe: Double?
}

class WatchDataRelayService: NSObject, WCSessionDelegate {
    static let shared = WatchDataRelayService()

    private var session: WCSession?
    private let userSettingsService = UserSettingsService.shared
    private let apiService = APIService() // APIServiceのインスタンスを追加
    // APIServiceは種目名を取得するために後で使用する可能性があります
    // private let apiService = APIService() 

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("WCSession activated on iPhone")
        } else {
            print("WCSession is not supported on this device.")
        }
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            if session == nil { // まだ初期化されていない場合のみ
                session = WCSession.default
                session?.delegate = self
            }
            if session?.activationState != .activated {
                 session?.activate()
                 print("WCSession explicitly activated in setup.")
            } else {
                print("WCSession was already activated.")
            }
        } else {
            print("WCSession is not supported on this device (called from setup).")
        }
    }

    // MARK: - WCSessionDelegate Methods

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession on iPhone did become inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession on iPhone did deactivate.")
        // セッションが非アクティブ化された場合、再アクティベートを試みる
        self.session?.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed on iPhone: \(error.localizedDescription)")
            return
        }
        print("WCSession activated on iPhone with state: \(activationState.rawValue)")
        // アクティベーション完了時に最新データを送信するなどの処理も可能
        sendRecentWorkoutsToWatch()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("iPhone received message: \(message)")
        if message["request"] as? String == "recentWorkouts" {
            // Watchからデータリクエストがあった場合 (最近の種目)
            let allLastSessions = userSettingsService.getAllLastWorkoutSessions()
            let sortedSessions = allLastSessions.sorted { $0.recordedDate > $1.recordedDate }
            let recentSessionsToShow = Array(sortedSessions.prefix(5)) // 最新5件

            if recentSessionsToShow.isEmpty {
                print("WatchDataRelayService: No recent sessions to reply to watch.")
                replyHandler(["recentWorkouts": Data()])
                return
            }
            let recentExerciseIds = recentSessionsToShow.map { $0.exerciseId }
            fetchAndReplyWithExerciseDetails(exerciseIds: recentExerciseIds, forKey: "recentWorkouts", replyHandler: replyHandler)

        } else if message["request"] as? String == "allExercises" {
            // Watchからデータリクエストがあった場合 (全ての種目)
            apiService.fetchExercises(query: nil, locale: nil) { result in // nil localeで全ての言語のものを取得、または適切なlocaleを指定
                switch result {
                case .success(let allExercises):
                    // 最大50件に制限
                    let limitedExercises = Array(allExercises.prefix(50))
                    let watchWorkouts = limitedExercises.map {
                        WatchWorkoutData(id: $0.id, name: $0.name ?? $0.canonicalName)
                    }
                    do {
                        let data = try JSONEncoder().encode(watchWorkouts)
                        replyHandler(["allExercises": data])
                        print("Sent \(watchWorkouts.count) all exercises data to Watch in reply.")
                    } catch {
                        print("Error encoding all exercises for reply: \(error.localizedDescription)")
                        replyHandler(["error": "Failed to encode all exercises data"])
                    }
                case .failure(let error):
                    print("Failed to fetch all exercises for Watch reply: \(error.localizedDescription)")
                    replyHandler(["error": "Failed to fetch all exercises"])
                }
            }
        } else if let testMessageText = message["testMessage"] as? String {
            // Watchからのテストメッセージを受信
            print("iPhone received test message: \(testMessageText)")
            // ここでiPhone側の任意の処理を実行できます。
            // 例えば、UIに表示したり、ローカル通知を発行したりなど。
            replyHandler(["status": "Test message received by iPhone: \(testMessageText)"])
        } else if let setData = message["newWorkoutSet"] as? Data,
                  let exerciseId = message["exerciseId"] as? String,
                  let exerciseName = message["exerciseName"] as? String {
            // Watchから新しいワークアウトセット情報を受信
            print("iPhone received newWorkoutSet for exerciseID: \(exerciseId) (\(exerciseName))")
            do {
                let decoder = JSONDecoder()
                let setInfo = try decoder.decode(ReceivedWorkoutSetInfo.self, from: setData)
                print("Decoded set: Weight: \(setInfo.weight) kg, Reps: \(setInfo.reps), RPE: \(setInfo.rpe != nil ? String(format: "%.1f", setInfo.rpe!) : "N/A")")
                
                // performedAt をISO8601形式の文字列で生成
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // .sssZ を含む形式
                let performedAtString = isoFormatter.string(from: Date())

                // WorkoutSetCreate オブジェクトを作成 (OpenAPIスキーマに準拠)
                let setCreate = WorkoutSetCreate(
                    exerciseId: exerciseId,
                    weight: Float(setInfo.weight),
                    reps: setInfo.reps,
                    rpe: setInfo.rpe != nil ? Float(setInfo.rpe!) : nil,
                    performedAt: performedAtString
                    // notes: nil // 必要であれば追加
                )

                apiService.createWorkoutSet(setCreate: setCreate) { result in // sessionId引数なしのメソッドを呼び出し
                    switch result {
                    case .success(let response):
                        print("Successfully saved workout set to server. Response: \(response)")
                        replyHandler(["success": true, "message": "Set data saved for \(exerciseName)."])
                    case .failure(let error):
                        print("Failed to save workout set to server: \(error.localizedDescription)")
                        replyHandler(["success": false, "error": "Failed to save set data on server for \(exerciseName): \(error.localizedDescription)"])
                    }
                }
            } catch {
                print("Failed to decode ReceivedWorkoutSetInfo: \(error.localizedDescription)")
                replyHandler(["success": false, "error": "Failed to decode set data on iPhone: \(error.localizedDescription)"])
            }
        } else {
            replyHandler([:]) // 不明なメッセージ
        }
    }

    // 共通の種目詳細取得・返信ロジック
    private func fetchAndReplyWithExerciseDetails(exerciseIds: [String], forKey key: String, replyHandler: @escaping ([String : Any]) -> Void) {
        apiService.fetchExercises(query: nil, locale: nil) { result in // 全種目取得してIDでフィルタリング
            switch result {
            case .success(let allExercises):
                let exercisesDict = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })
                var watchWorkouts: [WatchWorkoutData] = []
                for exerciseId in exerciseIds {
                    if let exercise = exercisesDict[exerciseId] {
                        let workoutName = exercise.name ?? exercise.canonicalName
                        watchWorkouts.append(WatchWorkoutData(id: exercise.id, name: workoutName))
                    } else {
                        watchWorkouts.append(WatchWorkoutData(id: exerciseId, name: "不明な種目 (ID: \(exerciseId.prefix(8)))"))
                    }
                }
                do {
                    let data = try JSONEncoder().encode(watchWorkouts)
                    replyHandler([key: data])
                    print("Sent \(watchWorkouts.count) items for key '\\[key]' to Watch in reply.")
                } catch {
                    print("Error encoding \(key) for reply: \(error.localizedDescription)")
                    replyHandler(["error": "Failed to encode \(key) data"])
                }
            case .failure(let error):
                print("Failed to fetch exercises for \(key) reply: \(error.localizedDescription)")
                replyHandler(["error": "Failed to fetch exercise names for \(key)"])
            }
        }
    }

    // MARK: - Data Sending Methods

    // UserSettingsServiceから最近のワークアウト履歴を取得し、Watchに送信する
    // このメソッドは、iPhoneアプリ側でデータが更新されたときなどに呼び出す
    public func sendRecentWorkoutsToWatch() {
        guard let validSession = session, validSession.isPaired, validSession.isWatchAppInstalled else {
            print("WCSession not ready or WatchApp not installed.")
            if !(session?.isPaired ?? false) { print("Watch not paired.") }
            if !(session?.isWatchAppInstalled ?? false) { print("Watch App not installed.")}
            return
        }

        // 1. UserSettingsServiceから全ての最終セッション記録を取得
        let allLastSessions = userSettingsService.getAllLastWorkoutSessions()

        // 2. recordedDateで降順ソートし、最新N件を取得 (例: 5件)
        let sortedSessions = allLastSessions.sorted { $0.recordedDate > $1.recordedDate }
        let recentSessionsToShow = Array(sortedSessions.prefix(5))

        if recentSessionsToShow.isEmpty {
            print("WatchDataRelayService: No recent sessions to send to watch.")
            // 空のデータを送信することも検討（Watch側で「データなし」と表示させるため）
            try? validSession.updateApplicationContext(["recentWorkouts": Data()])
            return
        }

        let recentExerciseIds = recentSessionsToShow.map { $0.exerciseId }

        // 3. APIServiceから種目情報を取得 (ここでは全種目取得を仮定)
        //    実際には、必要なIDのみを取得するAPIやキャッシュ戦略を検討するとより効率的
        apiService.fetchExercises(query: nil, locale: nil) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let allExercises):
                let exercisesDict = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })
                
                var watchWorkouts: [WatchWorkoutData] = []
                for sessionId in recentExerciseIds {
                    if let exercise = exercisesDict[sessionId] {
                        let workoutName = exercise.name ?? exercise.canonicalName
                        watchWorkouts.append(WatchWorkoutData(id: exercise.id, name: workoutName))
                    } else {
                        // 種目情報が見つからなかった場合のフォールバック
                        watchWorkouts.append(WatchWorkoutData(id: sessionId, name: "不明な種目 (ID: \(sessionId.prefix(8)))"))
                    }
                }
                
                // 重複排除 (同じ種目が複数回最近使われていても1つにまとめる場合はここで処理)
                // watchWorkouts = Array(Set(watchWorkouts)) // WatchWorkoutDataがHashableである必要あり
                // または、送信前にIDベースでユニークにするなど

                do {
                    let contextData = try JSONEncoder().encode(watchWorkouts)
                    try validSession.updateApplicationContext(["recentWorkouts": contextData])
                    print("Sent application context with \(watchWorkouts.count) recent workouts to Watch.")
                } catch {
                    print("Error encoding or sending workout data to Watch: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("Failed to fetch exercises for Watch data: \(error.localizedDescription)")
                // エラー時は空のデータを送るか、以前のデータを維持するか、Watch側でエラー表示させるかなど検討
            }
        }
    }
}
