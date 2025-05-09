//
//  AddPlaceholderView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

struct AddPlaceholderView: View {
    @EnvironmentObject var sessionManager: SessionManager // SessionManager を環境オブジェクトとして受け取る
    @State private var selectionType: SelectionType = .individual // 選択状態を保持
    @StateObject private var viewModel = AddPlaceholderViewModel() // ViewModelをインスタンス化

    // ViewModelのexercisesプロパティへのアクセサー
    private var exercisesList: [Exercise] {
        viewModel.exercises
    }

    // 選択肢を定義するenum
    enum SelectionType: String, CaseIterable, Identifiable {
        case individual = "種目から選ぶ"
        case menu = "メニューから選ぶ"
        var id: String { self.rawValue }
    }

    var body: some View {
        // ここにモーダルとして表示したい内容を記述します。
        // 例として、以前のSampleModalViewのようなシンプルなTextを表示します。
        NavigationView { // モーダル内でナビゲーションが必要な場合など
            VStack(spacing: 10) {
                Picker("選択方法", selection: $selectionType) {
                    ForEach(SelectionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // 選択に応じて表示するコンテンツ
                switch selectionType {
                case .individual:
                    VStack(alignment: .leading) {
                        Text("よく行う種目") // TODO: APIから「よく使う種目」を取得するか、全種目リストにするか検討
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let errorMessage = viewModel.errorMessage {
                            Text("エラー: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if exercisesList.count == 0 {
                            Text("利用可能な種目がありません。")
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(exercisesList) { exercise in
                                        WorkoutItemCard(itemName: exercise.name ?? exercise.canonicalName)
                                            .onTapGesture {
                                                viewModel.selectExerciseAndStartSession(exercise: exercise, sessionManager: sessionManager)
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 120) // ScrollViewの高さを指定
                        }

                        // セッション開始時のローディングとエラー表示 (任意)
                        if viewModel.isStartingSession {
                            ProgressView("セッションを開始しています...")
                                .padding()
                        }
                        if let sessionError = viewModel.sessionError {
                            Text("セッション開始エラー: \(sessionError)")
                                .foregroundColor(.red)
                                .padding()
                        }

                        Spacer() // 残りのスペースを埋める
                    }
                case .menu:
                    Text("メニュー選択のUIをここに配置")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer() // 下部のスペースを確保し、コンテンツを上部に寄せる
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("トレーニングを開始する")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                }
            }
        }
        .onAppear {
            if selectionType == .individual { // 種目選択タブが表示されている場合のみ取得
                viewModel.fetchExercises()
            }
        }
        // タブが切り替わった時にもデータを取得する
        .onChange(of: selectionType) { _, newSelectionType in
            if newSelectionType == .individual {
                viewModel.fetchExercises()
            }
        }
        .fullScreenCover(isPresented: $viewModel.isShowingSessionModal) {
            // startedSessionId と selectedExerciseForSession が nil でないことを確認
            if let sessionId = viewModel.startedSessionId, let exercise = viewModel.selectedExerciseForSession {
                SessionWorkoutView(sessionId: sessionId, exercise: exercise, isPresented: $viewModel.isShowingSessionModal)
            } else {
                // 必要な情報が不足している場合のフォールバック
                VStack {
                    Text("セッション情報または種目情報が準備できませんでした。")
                    Button("閉じる") {
                        viewModel.isShowingSessionModal = false
                    }
                    .padding()
                }
            }
        }
    }
}

// AddPlaceholderView の struct の外に、WorkoutItemCard を定義します。
// もし別のファイルで共通化するなら、そちらに移動してください。
struct WorkoutItemCard: View {
    // let iconName: String // iconName プロパティを削除またはコメントアウト
    let itemName: String

    var body: some View {
        VStack {
            // TODO: 将来的には各アイテムに対応するアセットのアイコンを動的に表示する
            Image(systemName: "figure.strengthtraining.traditional") // 固定のアイコン
                .font(.largeTitle)
                .foregroundColor(.black) // アイコンの色を黒に変更
                .frame(height: 50)
            Text(itemName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(width: 100, height: 100)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray, lineWidth: 1)
        )
    }
}

#Preview {
    AddPlaceholderView()
}
