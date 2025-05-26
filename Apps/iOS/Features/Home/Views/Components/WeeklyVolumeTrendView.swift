import SwiftUI
import Charts
import Domain // WeekPointのため

struct WeeklyVolumeTrendView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme

    private var displayData: [WeekPointEntity] {
        guard let trendData = viewModel.dashboardData?.trend else {
            return []
        }
        
        // APIから取得したデータをそのまま使用し、日付順にソート
        return trendData.sorted(by: { $0.weekStart < $1.weekStart })
    }
    
    // Dateを "M/d" 形式の文字列にフォーマットするヘルパー関数
    private func formatDateToLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // "yyyy-MM-dd" 形式の文字列をDateに変換するヘルパー関数
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private var allVolumesAreZero: Bool {
        displayData.allSatisfy { $0.totalVolume == 0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("週間ボリュームの推移")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)

            if viewModel.isLoading {
                Spacer()
                ProgressView("グラフデータ読み込み中...")
                Spacer()
            } else if let specificError = viewModel.errorMessage {
                Spacer()
                Text("エラー: \(specificError)")
                    .foregroundColor(.red)
                Spacer()
            } else if viewModel.dashboardData?.trend != nil {
                ZStack {
                    Chart(displayData) { weekPoint in
                        BarMark(
                            x: .value("週", weekPoint.weekStart, unit: .day),
                            y: .value("総ボリューム", weekPoint.totalVolume)
                        )
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                        .cornerRadius(4)
                        .annotation(position: .top, alignment: .center) {
                            if !allVolumesAreZero { // 全てのボリュームが0の場合はアノテーションを非表示
                                Text("\(String(format: "%.0f", weekPoint.totalVolume))")
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                        }
                    }
                    .chartXScale(range: .plotDimension(padding: 40))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatDateToLabel(date))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(preset: .automatic, values: .automatic) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel() {
                                if let volume = value.as(Double.self) {
                                    Text("\(String(format: "%.0f", volume))")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...(allVolumesAreZero ? 1000 : (displayData.map{$0.totalVolume}.max() ?? 1000) * 1.2)) // Y軸のドメインを調整

                    if allVolumesAreZero && !viewModel.isLoading && viewModel.errorMessage == nil {
                        Text("データがありません")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(minHeight: 250)
            } else { // viewModel.dashboardData?.trend == nil の場合
                Spacer()
                // このケースは displayData が常に4週間のプレースホルダーを持つため、
                // viewModel.dashboardData?.trend が nil でもグラフ自体は表示される。
                // allVolumesAreZero が true になることで「データがありません」と表示される。
                // もし、trend自体がnilの場合に明確に別の表示をしたいなら、ここの条件分岐を調整。
                // 現状では、isLoading と errorMessage のチェックが先に行われる。
                Text("トレンドデータを取得できませんでした。")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(minHeight: 250, alignment: .center) // グラフエリアと同じ高さを確保
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
