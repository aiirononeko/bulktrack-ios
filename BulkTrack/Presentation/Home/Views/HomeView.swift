//
//  HomeView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager // SessionManager を受け取る
    @StateObject private var viewModel = HomeViewModel()

    private var currentDateFormatted: String { // ViewModelに移動するまではここに残す
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    TabView {
                        // 1ページ目: ダッシュボード
                        VStack(spacing: 0) {
                            Spacer() // 上のSpacer
                            if viewModel.isLoading {
                                ProgressView("読み込み中...")
                            } else if let data = viewModel.dashboardData { // dashboardData を使用
                                ScrollView { // データが多い場合にスクロール可能にする
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("ダッシュボード (期間: \(data.span))")
                                            .font(.title2).bold().padding(.bottom)

                                        // 今週のデータ
                                        weekDataView(title: "今週のデータ (\(formatWeekStartDate(data.thisWeek.weekStart)))", weekPoint: data.thisWeek)

                                        // 先週のデータ
                                        weekDataView(title: "先週のデータ (\(formatWeekStartDate(data.lastWeek.weekStart)))", weekPoint: data.lastWeek)
                                        
                                        // TODO: トレンドデータの表示
                                        // TODO: 部位別データの表示
                                        // TODO: メトリクスデータの表示

                                    }.padding()
                                }
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
                        VStack(spacing: 0) {
                            Spacer() // 上のSpacer
                            Text("グラフ コンテンツ")
                                .font(.title2)
                            Spacer() // 下のSpacer
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // 週次データを表示するためのヘルパーView
    @ViewBuilder
    private func weekDataView(title: String, weekPoint: WeekPoint) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            HStack {
                Text("総ボリューム:")
                Text("\(String(format: "%.1f", weekPoint.totalVolume)) kg")
            }
            HStack {
                Text("平均セットボリューム:")
                Text("\(String(format: "%.1f", weekPoint.avgSetVolume)) kg")
            }
            if let e1rm = weekPoint.e1rmAvg {
                HStack {
                    Text("平均E1RM:")
                    Text("\(String(format: "%.1f", e1rm)) kg")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
