import Foundation
import WatchConnectivity

// iPhoneから送信される種目データの構造体
struct WorkoutData: Identifiable, Codable {
    let id: String
    let name: String
    // 必要に応じて他のプロパティ（最終実施日、アイコン名など）を追加
    // let lastPerformedDate: Date?
}

// WatchからiPhoneへ送信するセット情報の構造体
struct WorkoutSetInfo: Codable, Identifiable {
    let id = UUID() // 各セットを識別するため (リスト表示などで使う場合)
    let weight: Double
    let reps: Int
    let rpe: Double?
    // let exerciseId: String // どの種目のセットか (送信時に別途付与するか、ここに含めるか検討)
    // let timestamp: Date // 記録時刻 (必要であれば)
}

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Published var recentWorkouts: [WorkoutData] = []
    @Published var allAvailableExercises: [WorkoutData] = [] // 全ての種目リスト用
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false // ローディング状態を追跡

    static let shared = WatchSessionManager()

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("WCSession activated on Watch")
        } else {
            print("WCSession is not supported on this device.")
            errorMessage = "WatchConnectivity is not supported."
        }
    }

    // MARK: - WCSessionDelegate methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "WCSession activation failed with error: \(error.localizedDescription)"
                print("WCSession activation failed: \(error.localizedDescription)")
                return
            }
            print("WCSession activation completed with state: \(activationState.rawValue)")
            // ここでiPhoneに初期データリクエストを送信することも検討できます
            // self.requestInitialDataFromPhone()
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("Watch received userInfo: \(userInfo)")
        DispatchQueue.main.async {
            if let workoutDataArray = userInfo["recentWorkouts"] as? Data {
                let decoder = JSONDecoder()
                if let decodedWorkouts = try? decoder.decode([WorkoutData].self, from: workoutDataArray) {
                    self.recentWorkouts = decodedWorkouts
                    self.errorMessage = nil
                    print("Successfully decoded and updated recentWorkouts on Watch: \(decodedWorkouts.count) items")
                    // デバッグ: 各種目の詳細を出力
                    for workout in decodedWorkouts {
                        print("Recent workout decoded - ID: \(workout.id), Name: \(workout.name)")
                    }
                } else {
                    self.errorMessage = "Failed to decode recent workout data."
                    print("Failed to decode recent workout data from userInfo")
                }
            } else if let allExercisesDataArray = userInfo["allExercises"] as? Data { // 全種目データ受信処理
                let decoder = JSONDecoder()
                if let decodedExercises = try? decoder.decode([WorkoutData].self, from: allExercisesDataArray) {
                    self.allAvailableExercises = decodedExercises
                    self.errorMessage = nil
                    print("Successfully decoded and updated allAvailableExercises on Watch: \(decodedExercises.count) items")
                    // デバッグ: 各種目の詳細を出力
                    for exercise in decodedExercises {
                        print("Exercise decoded - ID: \(exercise.id), Name: \(exercise.name)")
                    }
                } else {
                    self.errorMessage = "Failed to decode all exercises data."
                    print("Failed to decode all exercises data from userInfo")
                }
            } else {
                print("Did not find expected key in userInfo or data was not of expected type.")
            }
        }
    }

    // iPhoneにデータリクエストを送信する（オプション）
    func requestRecentWorkoutsFromPhone() {
        guard let validSession = session, validSession.isReachable else {
            print("iPhone is not reachable to request data.")
            DispatchQueue.main.async {
                self.errorMessage = "iPhone is not reachable."
                self.isLoading = false
            }
            return
        }

        // ローディング状態をONに設定
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let message = ["request": "recentWorkouts"]
        validSession.sendMessage(message, replyHandler: { replyMessage in
            // iPhoneからの返信メッセージを処理
            print("Received reply for recentWorkouts. Keys: \(replyMessage.keys)") 

            DispatchQueue.main.async {
                if let workoutDataArray = replyMessage["recentWorkouts"] as? Data {
                    print("Processing recentWorkouts data...")
                    let decoder = JSONDecoder()
                    if let decodedWorkouts = try? decoder.decode([WorkoutData].self, from: workoutDataArray) {
                        self.recentWorkouts = decodedWorkouts
                        self.errorMessage = nil
                        self.isLoading = false // ローディング状態をOFFに設定
                        print("Successfully updated recentWorkouts from iPhone reply: \(self.recentWorkouts.count) items")
                    } else {
                        self.errorMessage = "Failed to decode recent workout data from iPhone reply."
                        self.isLoading = false // エラー時もローディング状態をOFF
                        print("Failed to decode recent workout data from iPhone reply")
                    }
                } else if let errorMsg = replyMessage["error"] as? String {
                     self.errorMessage = errorMsg
                     self.isLoading = false // エラー時もローディング状態をOFF
                     print("Received error in reply for recentWorkouts: \(errorMsg)")
                } else {
                    print("Reply for recentWorkouts received, but no expected keys found or data type mismatch.")
                    self.isLoading = false // 不明なレスポンスでもローディング状態をOFF
                }
            }
        }, errorHandler: { error in
            print("Error sending message to iPhone: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error requesting data from iPhone: \(error.localizedDescription)"
                self.isLoading = false // エラー時もローディング状態をOFF
            }
        })
        print("Sent request for recent workouts to iPhone.")
    }

    func requestAllExercises() {
        guard let validSession = session, validSession.isReachable else {
            print("iPhone is not reachable to request all exercises data.")
            DispatchQueue.main.async {
                self.errorMessage = "iPhone is not reachable."
                self.isLoading = false
            }
            return
        }

        // ローディング状態をONに設定
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let message = ["request": "allExercises"]
        validSession.sendMessage(message, replyHandler: { replyMessage in
            // ★★★ このハンドラが呼び出された直後の replyMessage を確認 ★★★
            print("Specific replyHandler for allExercises - Received replyMessage. Keys: \(replyMessage.keys), Content: \(replyMessage)")

            DispatchQueue.main.async {
                if let allExercisesDataArray = replyMessage["allExercises"] as? Data {
                    print("Specific Handler: Processing allExercises data...")
                    let decoder = JSONDecoder()
                    if let decodedExercises = try? decoder.decode([WorkoutData].self, from: allExercisesDataArray) {
                        print("Specific Handler: Watch decoded allExercises: \(decodedExercises.count) items. First: \(decodedExercises.first?.name ?? "N/A")")
                        self.allAvailableExercises = decodedExercises
                        print("Specific Handler: Watch self.allAvailableExercises updated. Count: \(self.allAvailableExercises.count)")
                        self.errorMessage = nil
                        self.isLoading = false // ローディング状態をOFFに設定
                    } else {
                        self.errorMessage = "Specific Handler: Failed to decode all exercises data from iPhone reply."
                        print("Specific Handler: Failed to decode all exercises data from iPhone reply")
                    }
                } else if let errorMsg = replyMessage["error"] as? String {
                     self.errorMessage = errorMsg
                     self.isLoading = false // エラー時もローディング状態をOFF
                     print("Specific Handler: Received error in reply from iPhone: \(errorMsg)")
                } else {
                    print("Specific Handler: Reply received, but no 'allExercises' key or 'error' key found. All keys: \(replyMessage.keys)")
                    self.isLoading = false // 不明なレスポンスでもローディング状態をOFF
                }
            }

        }, errorHandler: { error in
            print("Error sending allExercises request to iPhone: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error requesting all exercises: \(error.localizedDescription)"
                self.isLoading = false // エラー時もローディング状態をOFF
            }
        })
        print("Sent request for all exercises to iPhone.")
    }

    // MARK: - Test Message Sending
    func sendTestMessageToPhone(messageText: String) {
        guard let validSession = session, validSession.isReachable else {
            print("iPhone is not reachable to send a test message.")
            DispatchQueue.main.async {
                self.errorMessage = "iPhone is not reachable to send test message."
            }
            return
        }

        let message = ["testMessage": messageText]
        validSession.sendMessage(message, replyHandler: { reply in
            print("Received reply for test message: \(reply)")
            DispatchQueue.main.async {
                // 必要であれば返信内容に応じた処理を追加
            }
        }, errorHandler: { error in
            print("Error sending test message to iPhone: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error sending test message: \(error.localizedDescription)"
            }
        })
        print("Sent test message to iPhone: \(messageText)")
    }

    // MARK: - Workout Set Sending
    func sendWorkoutSetToPhone(setInfo: WorkoutSetInfo, exerciseId: String, exerciseName: String) {
        guard let validSession = session, validSession.isReachable else {
            print("iPhone is not reachable to send workout set.")
            DispatchQueue.main.async {
                self.errorMessage = "iPhone is not reachable to send workout set."
            }
            return
        }

        do {
            let setData = try JSONEncoder().encode(setInfo)
            let message: [String: Any] = [
                "newWorkoutSet": setData,
                "exerciseId": exerciseId,
                "exerciseName": exerciseName // iPhone側での確認や表示用
            ]

            validSession.sendMessage(message, replyHandler: { reply in
                print("Received reply for newWorkoutSet: \(reply)")
                DispatchQueue.main.async {
                    if let success = reply["success"] as? Bool, success {
                        // iPhone側での保存成功
                        self.errorMessage = nil // エラーメッセージをクリア
                    } else if let errorMsg = reply["error"] as? String {
                        self.errorMessage = "Failed to save set on iPhone: \(errorMsg)"
                    }
                }
            }, errorHandler: { error in
                print("Error sending newWorkoutSet to iPhone: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error sending set: \(error.localizedDescription)"
                }
            })
            print("Sent newWorkoutSet to iPhone for exercise: \(exerciseName)")
        } catch {
            print("Failed to encode WorkoutSetInfo: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encode set data."
            }
        }
    }
}
