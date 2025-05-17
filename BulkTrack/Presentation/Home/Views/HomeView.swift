//
//  HomeView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI
import Charts

// グラフ表示専用のプライベートView
private struct TrendGraphView: View {
    let trendData: [WeekPoint]?
    let isLoading: Bool
    let errorMessage: String?
    let colorScheme: ColorScheme
    let formatWeekStartDate: (String) -> String

    // 過去N週間の週開始日（月曜日）の文字列リストを生成する
    private func generatePastWeekDates(count: Int) -> [String] {
        var dates: [String] = []
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // 現在の週の月曜日を見つける
        let weekday = calendar.component(.weekday, from: today) // Sunday=1, Monday=2, ...
        // firstWeekdayが日曜(1)の場合、月曜日は2。月曜を基準にする。
        // (weekday - calendar.firstWeekday - 1 + 7) % 7 で月曜からのオフセットを計算することもできるが、
        // ここでは単純に (weekday == 1 ? -6 : 2 - weekday) で月曜までの日数を計算
        let daysToSubtractToGetMonday = (weekday == calendar.firstWeekday) ? 6 : (weekday - (calendar.firstWeekday + 1) % 7) 
        // weekdayが2(月)なら0, 3(火)なら-1, ... 1(日)なら-6 (firstWeekday=1 Sun)
        // weekdayが1(日)なら6, 2(月)なら0, 3(火)なら1日引く (シンプルに月曜に合わせる)
        let simplifiedDaysToSubtract = (weekday == 1) ? 6 : (weekday - 2)

        guard let currentWeekMonday = calendar.date(byAdding: .day, value: -simplifiedDaysToSubtract, to: today) else {
            return [] // エラーケース
        }

        for i in 0..<count {
            if let date = calendar.date(byAdding: .weekOfYear, value: -(count - 1 - i), to: currentWeekMonday) {
                dates.append(dateFormatter.string(from: date))
            }
        }
        return dates // 過去から現在へソート済みのはず
    }

    private var displayData: [WeekPoint] {
        let pastFourWeekDates = generatePastWeekDates(count: 4)
        
        var placeholderData: [WeekPoint] = pastFourWeekDates.map { dateString in
            // APIService.swiftのWeekPoint構造体に従う
            WeekPoint(weekStart: dateString, totalVolume: 0, avgSetVolume: 0, e1rmAvg: nil)
        }
        
        if let actualTrendData = self.trendData {
            for actualPoint in actualTrendData {
                if let index = placeholderData.firstIndex(where: { $0.weekStart == actualPoint.weekStart }) {
                    placeholderData[index] = actualPoint
                }
                // もし placeholderData に該当する週がない場合、APIからの余分なデータはここでは無視される
                // (常に4週表示のため)
            }
        }
        return placeholderData
    }

    var body: some View {
        VStack() {
            HStack {
                Text("週間ボリュームの推移")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)

            if isLoading {
                Spacer()
                ProgressView("グラフデータ読み込み中...")
                Spacer()
            } else if let specificError = errorMessage {
                Spacer()
                Text("エラー: \(specificError)")
                    .foregroundColor(.red)
                Spacer()
            } else {
                // ローディング完了、エラーなしの場合、displayDataでグラフ表示
                Chart(displayData) { weekPoint in
                    BarMark(
                        x: .value("週", formatWeekStartDate(weekPoint.weekStart)),
                        y: .value("総ボリューム", weekPoint.totalVolume)
                    )
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    .annotation(position: .top, alignment: .center) {
                        Text("\(String(format: "%.0f", weekPoint.totalVolume)) kg")
                            .font(.caption)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        // AxisGridLine() // 縦のグリッド線を削除
                        AxisTick()
                        AxisValueLabel {
                            if let dateStr = value.as(String.self) {
                                Text(dateStr)
                                    .font(.caption)
                            }
                        }
                    }
                }
                // Y軸のグリッド線とラベルはデフォルトまたは以前の設定のまま
                .chartYAxis {
                     AxisMarks(preset: .automatic, values: .automatic) { value in
                         AxisGridLine() // Y軸のグリッド線は残す場合
                         AxisTick()
                         AxisValueLabel() {
                             if let volume = value.as(Double.self) {
                                 Text("\(String(format: "%.0f", volume))") // kg はBarMarkのアノテーションにあるので重複を避ける
                                     .font(.caption)
                             }
                         }
                     }
                 }
                .padding()
                .frame(height: 340)  // グラフの高さを指定して低くする
            }
            Spacer() // グラフと区切り線の間にSpacerを追加して、コンテンツを上寄せにする
            
            Rectangle() // 下の区切り線
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 週間平均RMの推移グラフ専用のプライベートView
private struct AverageRMGraphView: View {
    let trendData: [WeekPoint]?
    let isLoading: Bool
    let errorMessage: String?
    let colorScheme: ColorScheme
    let formatWeekStartDate: (String) -> String

    // 過去N週間の週開始日（月曜日）の文字列リストを生成する
    private func generatePastWeekDates(count: Int) -> [String] {
        var dates: [String] = []
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let weekday = calendar.component(.weekday, from: today)
        let simplifiedDaysToSubtract = (weekday == 1) ? 6 : (weekday - 2)

        guard let currentWeekMonday = calendar.date(byAdding: .day, value: -simplifiedDaysToSubtract, to: today) else {
            return []
        }

        for i in 0..<count {
            if let date = calendar.date(byAdding: .weekOfYear, value: -(count - 1 - i), to: currentWeekMonday) {
                dates.append(dateFormatter.string(from: date))
            }
        }
        return dates
    }

    private var displayData: [WeekPoint] {
        let pastFourWeekDates = generatePastWeekDates(count: 4)
        
        var placeholderData: [WeekPoint] = pastFourWeekDates.map { dateString in
            WeekPoint(weekStart: dateString, totalVolume: 0, avgSetVolume: 0, e1rmAvg: nil)
        }
        
        if let actualTrendData = self.trendData {
            for actualPoint in actualTrendData {
                if let index = placeholderData.firstIndex(where: { $0.weekStart == actualPoint.weekStart }) {
                    placeholderData[index] = actualPoint
                }
            }
        }
        return placeholderData
    }

    var body: some View {
        VStack() {
            HStack {
                Text("週間平均RMの推移")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)

            if isLoading {
                Spacer()
                ProgressView("グラフデータ読み込み中...")
                Spacer()
            } else if let specificError = errorMessage {
                Spacer()
                Text("エラー: \(specificError)")
                    .foregroundColor(.red)
                Spacer()
            } else {
                Chart(displayData.filter { $0.e1rmAvg != nil && $0.e1rmAvg ?? 0 > 0 }) { weekPoint in // e1rmAvgがnilでない、または0より大きいデータのみプロット
                    LineMark(
                        x: .value("週", formatWeekStartDate(weekPoint.weekStart)),
                        y: .value("平均RM", weekPoint.e1rmAvg ?? 0)
                    )
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    .symbol(Circle().strokeBorder(lineWidth: 2)) // データポイントにマーカーを追加

                    PointMark(
                        x: .value("週", formatWeekStartDate(weekPoint.weekStart)),
                        y: .value("平均RM", weekPoint.e1rmAvg ?? 0)
                    )
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                    .annotation(position: .top, alignment: .center) {
                        Text("\(String(format: "%.1f", weekPoint.e1rmAvg ?? 0)) kg")
                            .font(.caption)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisTick()
                        AxisValueLabel {
                            if let dateStr = value.as(String.self) {
                                Text(dateStr)
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
                .padding()
                .frame(height: 340)
            }
            Spacer()
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager // SessionManager を受け取る
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.colorScheme) var colorScheme // カラースキームを検出

    private var currentDateFormatted: String { // ViewModelに移動するまではここに残す
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack() {
                    TabView {
                        // 1ページ目: ダッシュボード
                        VStack(spacing: 0) {
                            if viewModel.isLoading {
                                ProgressView("読み込み中...")
                            } else if let data = viewModel.dashboardData { // dashboardData を使用
                                // 全体をVStackで囲む
                                VStack(spacing: 0) {
                                    // 1段目: タイトル
                                    HStack {
                                        Text("今週のボリューム")
                                            .font(.title2.bold())
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top)
                                    
                                    // プログレスバー
                                    ZStack {
                                        let startAngleDegrees = -30.0 + 180.0 // 上下反転のため180度加算
                                        let endAngleDegrees = 210.0 + 180.0   // 上下反転のため180度加算
                                        // 時計回りのスイープ角度を計算
                                        let sweepDegrees = (endAngleDegrees - startAngleDegrees + 360.0).truncatingRemainder(dividingBy: 360.0)

                                        // 背景の円弧 (トラック)
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(sweepDegrees / 360.0))
                                            .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                                            .opacity(0.3)
                                            .foregroundColor(Color.gray)
                                            .rotationEffect(Angle(degrees: startAngleDegrees))

                                        // 進捗を示す円弧
                                        let progress = min(1.0, max(0.0, (data.lastWeek.totalVolume * 1.02 > 0 ? data.thisWeek.totalVolume / (data.lastWeek.totalVolume * 1.01) : 0)))
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(progress * (sweepDegrees / 360.0)))
                                            .stroke(style: StrokeStyle(lineWidth: 24.0, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .rotationEffect(Angle(degrees: startAngleDegrees))
                                            .animation(.linear, value: progress)

                                        VStack {
                                            Text("今週の総ボリューム")
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                            Text("\(String(format: "%.0f", data.thisWeek.totalVolume)) kg")
                                                .font(.system(size: 36, weight: .bold))
                                        }
                                        // .padding(25) // プログレスバーの内側にパディングを追加 (値を調整可能)
                                    }
                                    .frame(width: 240, height: 240) // プログレスバーのサイズを大きくする
                                    .padding(.top, 40) // 上に少しマージンを追加

                                    // 2段目: 先週の総ボリュームと目標ボリューム
                                    HStack(alignment: .center, spacing: 20) {
                                        Spacer()
                                        // 残りボリューム
                                        VStack {
                                            Text("残りボリューム")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            let targetVolume = data.lastWeek.totalVolume * 1.02
                                            let remainingVolume = max(0, targetVolume - data.thisWeek.totalVolume)
                                            Text("\(String(format: "%.0f", remainingVolume)) kg")
                                                .font(.system(size: 30, weight: .medium))
                                        }
                                        Spacer()
                                        // 今週の目標ボリューム
                                        VStack {
                                            Text("目標ボリューム")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Text("\(String(format: "%.0f", data.lastWeek.totalVolume * 1.02)) kg")
                                                .font(.system(size: 30, weight: .medium))
                                        }
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.bottom, 20)

                            } else if let errorMessage = viewModel.errorMessage {
                                Text("エラー: \(errorMessage)")
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                Text("データを取得できませんでした。")
                            }
                            Spacer() // 下のSpacer
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // 2ページ目: グラフ
                        TrendGraphView(
                            trendData: viewModel.dashboardData?.trend,
                            isLoading: viewModel.isLoading,
                            errorMessage: viewModel.errorMessage,
                            colorScheme: colorScheme,
                            formatWeekStartDate: self.formatWeekStartDate
                        )
                        // 3ページ目: 平均RMグラフ
                        AverageRMGraphView(
                            trendData: viewModel.dashboardData?.trend,
                            isLoading: viewModel.isLoading,
                            errorMessage: viewModel.errorMessage,
                            colorScheme: colorScheme,
                            formatWeekStartDate: self.formatWeekStartDate
                        )
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: geometry.size.height * 2 / 3)
                    
                    Spacer()
                }
            }
            .navigationTitle("ホーム")
            .onAppear { // Viewが表示されたときにデータを取得開始
                viewModel.fetchDashboardData()
            }
        }
    }
    
    // 週の開始日をフォーマットするヘルパー関数
    private func formatWeekStartDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd" // APIから来る日付のフォーマット
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "M月d日"
        outputFormatter.locale = Locale(identifier: "ja_JP")
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString // パース失敗時は元の文字列を返す
    }
}

#Preview {
    HomeView()
}
