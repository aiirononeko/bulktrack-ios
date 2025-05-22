import Foundation

public struct WeekPointEntity: Identifiable, Equatable {
    public let id: String // weekStart を ID として使用
    public let weekStart: Date
    public let totalVolume: Double
    public let avgSetVolume: Double
    public let e1rmAvg: Double?

    public init(
        weekStart: Date,
        totalVolume: Double,
        avgSetVolume: Double,
        e1rmAvg: Double?
    ) {
        // DateをYYYY-MM-DD形式の文字列にしてidとする
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.id = dateFormatter.string(from: weekStart)
        self.weekStart = weekStart
        self.totalVolume = totalVolume
        self.avgSetVolume = avgSetVolume
        self.e1rmAvg = e1rmAvg
    }
}
