import SwiftUI
import Charts
import Domain // WeekPointEntityのため

struct WeeklyAverageRMView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme

    // Dateを "M/d" 形式の文字列にフォーマットするヘルパー関数
    private func formatDateToLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private var displayData: [WeekPointEntity] {
        guard let trendData = viewModel.dashboardData?.trend else {
            return []
        }
        
        // APIから取得したデータをそのまま使用し、日付順にソート
        return trendData.sorted(by: { $0.weekStart < $1.weekStart })
    }

    private var allRMAreZeroOrNil: Bool {
        displayData.allSatisfy { ($0.e1rmAvg ?? 0) == 0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("週間平均RMの推移")
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
            } else if viewModel.dashboardData?.trend != nil { // trendがnilでないことを確認
                ZStack {
                    Chart { // フィルタリングせずに全データを渡す
                        ForEach(displayData) { weekPoint in
                            // e1rmAvg が有効な場合のみ LineMark と PointMark を描画
                            if let e1rm = weekPoint.e1rmAvg, e1rm > 0 {
                                LineMark(
                                    x: .value("週", weekPoint.weekStart, unit: .day),
                                    y: .value("平均RM", e1rm)
                                )
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                .symbol(Circle().strokeBorder(lineWidth: 2))

                                PointMark(
                                    x: .value("週", weekPoint.weekStart, unit: .day),
                                    y: .value("平均RM", e1rm)
                                )
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                .annotation(position: .top, alignment: .center) {
                                    Text("\(String(format: "%.1f", e1rm))")
                                        .font(.caption)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                            } else {
                                // データがない場合でもX軸のポイントを確保するために透明なポイントを置くことも検討できるが、
                                // LineMarkは連続性が途切れるため、ここでは何もしない。
                                // X軸のラベルは表示される。
                            }
                        }
                    }
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
                                if let rmValue = value.as(Double.self) {
                                    Text("\(String(format: "%.0f", rmValue))")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...(allRMAreZeroOrNil ? 50 : (displayData.compactMap{$0.e1rmAvg}.max() ?? 50) * 1.2)) // Y軸のドメインを調整

                    if allRMAreZeroOrNil && !viewModel.isLoading && viewModel.errorMessage == nil {
                        Text("データがありません")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(minHeight: 250)
            } else {
                Spacer()
                Text("トレンドデータを取得できませんでした。")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(minHeight: 250, alignment: .center)
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
