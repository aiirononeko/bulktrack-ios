import Foundation
import WatchConnectivity

// iPhoneから送信される種目データの構造体
struct WorkoutData: Identifiable, Codable {
    let id: String
    let name: String
    // 必要に応じて他のプロパティ（最終実施日、アイコン名など）を追加
    // let lastPerformedDate: Date?
}

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Published var recentWorkouts: [WorkoutData] = []
    @Published var allAvailableExercises: [WorkoutData] = [] // 全ての種目リスト用
    @Published var errorMessage: String? = nil

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
            }
            return
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
                        print("Successfully updated recentWorkouts from iPhone reply: \(self.recentWorkouts.count) items")
                    } else {
                        self.errorMessage = "Failed to decode recent workout data from iPhone reply."
                        print("Failed to decode recent workout data from iPhone reply")
                    }
                } else if let errorMsg = replyMessage["error"] as? String {
                     self.errorMessage = errorMsg
                     print("Received error in reply for recentWorkouts: \(errorMsg)")
                } else {
                    print("Reply for recentWorkouts received, but no expected keys found or data type mismatch.")
                }
            }
        }, errorHandler: { error in
            print("Error sending message to iPhone: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error requesting data from iPhone: \(error.localizedDescription)"
            }
        })
        print("Sent request for recent workouts to iPhone.")
    }

    func requestAllExercises() {
        guard let validSession = session, validSession.isReachable else {
            print("iPhone is not reachable to request all exercises data.")
            DispatchQueue.main.async {
                self.errorMessage = "iPhone is not reachable."
            }
            return
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
                    } else {
                        self.errorMessage = "Specific Handler: Failed to decode all exercises data from iPhone reply."
                        print("Specific Handler: Failed to decode all exercises data from iPhone reply")
                    }
                } else if let errorMsg = replyMessage["error"] as? String {
                     self.errorMessage = errorMsg
                     print("Specific Handler: Received error in reply from iPhone: \(errorMsg)")
                } else {
                    print("Specific Handler: Reply received, but no 'allExercises' key or 'error' key found. All keys: \(replyMessage.keys)")
                }
            }

        }, errorHandler: { error in
            print("Error sending allExercises request to iPhone: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Error requesting all exercises: \(error.localizedDescription)"
            }
        })
        print("Sent request for all exercises to iPhone.")
    }
}
