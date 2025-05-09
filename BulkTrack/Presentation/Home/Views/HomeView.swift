//
//  HomeView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

struct HomeView: View {
    // ViewModelのインスタンスをStateObjectとして生成
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
                            } else if let summary = viewModel.currentWeekSummary {
                                VStack {
                                    Text("今週のサマリー")
                                        .font(.title3).padding(.bottom)
                                    Text("総ワークアウト回数: \(summary.totalWorkouts) 回")
                                    Text("総ボリューム: \(String(format: "%.1f kg", summary.totalVolume))")
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
}

#Preview {
    HomeView()
}
