//
//  AddPlaceholderView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

struct AddPlaceholderView: View {
    @Environment(\.dismiss) var dismiss // dismissアクションを取得
    @Environment(\.colorScheme) var colorScheme // カラーモードを取得
    @EnvironmentObject var sessionManager: SessionManager // SessionManager を環境オブジェクトとして受け取る
    @State private var selectionType: SelectionType = .individual // 選択状態を保持
    @StateObject private var viewModel = AddPlaceholderViewModel() // ViewModelをインスタンス化
    @State private var searchQuery: String = "" // 検索クエリ

    // ViewModelのexercisesプロパティへのアクセサー
    private var exercisesList: [Exercise] {
        viewModel.searchedExercises.isEmpty ? viewModel.recentExercises : viewModel.searchedExercises
    }

    // 選択肢を定義するenum
    enum SelectionType: String, CaseIterable, Identifiable {
        case individual = "種目から選ぶ"
        case menu = "メニューから選ぶ"
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // 上部の選択タブ
                Picker("選択タイプ", selection: $selectionType) {
                    ForEach(SelectionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // 選択タイプに応じたコンテンツ
                if selectionType == .individual {
                    TextField("種目を検索", text: $searchQuery)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchQuery) { _, newValue in
                            viewModel.searchExercises(query: newValue)
                        }

                    if !searchQuery.isEmpty && viewModel.isLoadingSearch {
                        ProgressView("検索中...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !searchQuery.isEmpty && !viewModel.searchedExercises.isEmpty {
                        Text("検索結果")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.horizontal, .top])
                        List(viewModel.searchedExercises) { exercise in
                            HStack {
                                Text(exercise.name ?? exercise.canonicalName)
                                Spacer()
                            }
                            .contentShape(Rectangle()) // タップ領域を広げる
                            .onTapGesture {
                                viewModel.selectExerciseAndStartSession(exercise: exercise, sessionManager: sessionManager)
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else if !searchQuery.isEmpty && viewModel.searchedExercises.isEmpty && !viewModel.isLoadingSearch {
                        Text("'\(searchQuery)' に一致する種目はありません。")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else { // searchQuery が空の場合、または検索結果がない場合（エラー表示は別途考慮）
                        Text("最近行った種目")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.horizontal, .top])

                        if viewModel.isLoadingRecent {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let errorMessage = viewModel.errorMessage, viewModel.recentExercises.isEmpty {
                            Text("エラー: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.recentExercises.isEmpty {
                            Text("最近行った種目はありません。")
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.recentExercises) { exercise in // recentExercises を使用
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
                    }
                    
                    Spacer() // 他のコンテンツを上部に押し上げる
                } else {
                    Text("メニュー選択のUIをここに配置")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer() // 下部のスペースを確保し、コンテンツを上部に寄せる
            }
            .navigationTitle("ワークアウト追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss() // モーダルを閉じる
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black) // カラーモードに応じて文字色を変更
                }
            }
            .sheet(isPresented: $viewModel.isShowingSessionModal) {
                if let sessionId = viewModel.startedSessionId, let exercise = viewModel.selectedExerciseForSession {
                    SessionWorkoutView(sessionId: sessionId, exercise: exercise, isPresented: $viewModel.isShowingSessionModal)
                        .environmentObject(sessionManager)
                } else {
                    // エラーまたは予期せぬ状態のフォールバック
                    Text("セッションを開始できませんでした。")
                }
            }
            .onAppear { // onAppearで最近の種目を読み込む
                viewModel.fetchRecentExercisesOnAppear()
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
