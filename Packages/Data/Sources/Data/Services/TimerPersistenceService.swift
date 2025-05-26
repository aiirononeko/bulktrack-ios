import Foundation
import Domain

/// タイマー状態の永続化サービス実装
/// UserDefaultsを使用してタイマー状態を保存・復元
public final class TimerPersistenceService: TimerPersistenceServiceProtocol {
    // MARK: - Constants
    private enum Keys {
        static let timerState = "BulkTrack.TimerState"
        static let backgroundTransitionTime = "BulkTrack.BackgroundTransitionTime"
        static let timerStateVersion = "BulkTrack.TimerState.Version"
    }
    
    private static let currentVersion = 1
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    public var hasPersistedTimerState: Bool {
        userDefaults.object(forKey: Keys.timerState) != nil
    }
    
    // MARK: - Initialization
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
        
        // ISO8601形式でDateをエンコード/デコード
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
}

// MARK: - Public Methods
public extension TimerPersistenceService {
    func saveTimerState(_ timerState: TimerState) {
        do {
            let persistedData = PersistedTimerData(from: timerState)
            let data = try jsonEncoder.encode(persistedData)
            
            userDefaults.set(data, forKey: Keys.timerState)
            userDefaults.set(Self.currentVersion, forKey: Keys.timerStateVersion)
            
            print("[TimerPersistenceService] Timer state saved successfully")
            print("[TimerPersistenceService] Saved state: \(timerState.status), remaining: \(timerState.formattedRemainingTime)")
        } catch {
            print("[TimerPersistenceService] Failed to save timer state: \(error)")
        }
    }
    
    func loadTimerState() -> TimerState? {
        guard let data = userDefaults.data(forKey: Keys.timerState) else {
            print("[TimerPersistenceService] No persisted timer state found")
            return nil
        }
        
        // バージョンチェック
        let version = userDefaults.integer(forKey: Keys.timerStateVersion)
        guard version == Self.currentVersion else {
            print("[TimerPersistenceService] Timer state version mismatch. Clearing old data.")
            clearTimerState()
            return nil
        }
        
        do {
            let persistedData = try jsonDecoder.decode(PersistedTimerData.self, from: data)
            let timerState = persistedData.toTimerState()
            
            print("[TimerPersistenceService] Timer state loaded successfully")
            print("[TimerPersistenceService] Loaded state: \(timerState.status), remaining: \(timerState.formattedRemainingTime)")
            
            return timerState
        } catch {
            print("[TimerPersistenceService] Failed to load timer state: \(error)")
            clearTimerState() // 破損したデータをクリア
            return nil
        }
    }
    
    func clearTimerState() {
        userDefaults.removeObject(forKey: Keys.timerState)
        userDefaults.removeObject(forKey: Keys.timerStateVersion)
        
        print("[TimerPersistenceService] Timer state cleared")
    }
    
    func saveBackgroundTransitionTime(_ date: Date) {
        userDefaults.set(date, forKey: Keys.backgroundTransitionTime)
        
        print("[TimerPersistenceService] Background transition time saved: \(date)")
    }
    
    func loadBackgroundTransitionTime() -> Date? {
        let date = userDefaults.object(forKey: Keys.backgroundTransitionTime) as? Date
        
        if let date = date {
            print("[TimerPersistenceService] Background transition time loaded: \(date)")
        } else {
            print("[TimerPersistenceService] No background transition time found")
        }
        
        return date
    }
    
    func clearBackgroundTransitionTime() {
        userDefaults.removeObject(forKey: Keys.backgroundTransitionTime)
        
        print("[TimerPersistenceService] Background transition time cleared")
    }
}

// MARK: - Private Methods
private extension TimerPersistenceService {
    func migrationNeeded(from version: Int) -> Bool {
        return version < Self.currentVersion
    }
    
    func performMigration(from version: Int) {
        print("[TimerPersistenceService] Performing migration from version \(version) to \(Self.currentVersion)")
        
        // 現在はversion 1のみなので、将来的なマイグレーション用
        switch version {
        case 0:
            // version 0 から version 1 へのマイグレーション
            // 現在は該当なし
            break
        default:
            print("[TimerPersistenceService] Unknown version \(version), clearing data")
            clearTimerState()
        }
        
        userDefaults.set(Self.currentVersion, forKey: Keys.timerStateVersion)
    }
}

// MARK: - Debug Helper
#if DEBUG
public extension TimerPersistenceService {
    func debugPrintPersistedData() {
        guard let data = userDefaults.data(forKey: Keys.timerState) else {
            print("[TimerPersistenceService] No persisted data to debug")
            return
        }
        
        do {
            let persistedData = try jsonDecoder.decode(PersistedTimerData.self, from: data)
            print("[TimerPersistenceService] Debug - Persisted data:")
            print("  Duration: \(persistedData.duration)")
            print("  Remaining: \(persistedData.remainingTime)")
            print("  Status: \(persistedData.status)")
            print("  Started at: \(persistedData.startedAt?.description ?? "nil")")
            print("  Persisted at: \(persistedData.persistedAt)")
        } catch {
            print("[TimerPersistenceService] Failed to debug persisted data: \(error)")
        }
    }
}
#endif
