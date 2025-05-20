import SwiftUI

struct WorkoutRecordingView: View {
    let selectedWorkout: WorkoutData // 選択された種目データを受け取る
    @StateObject private var sessionManager = WatchSessionManager.shared

    @State private var selectedWeight: Double = 50.0 // 初期値
    @State private var selectedReps: Int = 10 // 初期値
    @State private var selectedRpeIndex: Int = 0 // Pickerでの選択用。「なし」を含む
    @State private var recordedSets: [WorkoutSetInfo] = []
    @State private var showingAddSuccess: Bool = false // セット追加成功時のフィードバック用
    @State private var scrollProxy: ScrollViewProxy? = nil // スクロール制御用

    // RPEの選択肢。「なし」と具体的な数値
    let rpeOptions: [Double?] = [nil] + stride(from: 6.0, to: 10.5, by: 0.5).map { Optional($0) }

    // Pickerで表示するためのRPE文字列
    var rpeDisplayOptions: [String] {
        rpeOptions.map { rpe in
            if let rpeValue = rpe {
                return String(format: "%.1f", rpeValue)
            } else {
                return "なし"
            }
        }
    }
    
    // Pickerの選択肢
    let weightRange = stride(from: 0.0, to: 200.5, by: 0.5).map { $0 }
    let repsRange = Array(1...30)

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 8) {
                    // フォーム入力部分を横並び、ラベルと入力部分を縦並びに配置
                    HStack(spacing: 10) {
                        // 重量ピッカー
                        VStack(alignment: .center) {
                            Text("重量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("重量", selection: $selectedWeight) {
                                ForEach(weightRange, id: \.self) { weight in
                                    Text(String(format: "%.1f", weight)).tag(weight)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 60, height: 60)
                            
                            Text("kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // レップピッカー
                        VStack(alignment: .center) {
                            Text("レップ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("レップ数", selection: $selectedReps) {
                                ForEach(repsRange, id: \.self) { reps in
                                    Text("\(reps)").tag(reps)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 60, height: 60)
                            
                            Text("回")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // RPEピッカー
                        VStack(alignment: .center) {
                            Text("RPE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("RPE", selection: $selectedRpeIndex) {
                                ForEach(0..<rpeDisplayOptions.count, id: \.self) { index in
                                    Text(rpeDisplayOptions[index]).tag(index)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 60, height: 60)
                            
                            Text(" ")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 5)
                    
                    Button(action: addSet) {
                        HStack {
                            Text("記録する")
                            
                            // 追加成功時に一時的にチェックマークを表示
                            if showingAddSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.black)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.top, 5)
                    .padding(.horizontal, 30) // 水平方向のパディングを追加してはみ出しを防止
                    .animation(.easeInOut(duration: 0.3), value: showingAddSuccess)
                    
                    if !recordedSets.isEmpty {
                        Divider()
                        
                        HStack {
                            Text("記録済みセット")
                                .font(.headline)
                            Spacer()
                            Text("\(recordedSets.count)セット")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 5)
                        
                        // セット記録のヘッダー
                        HStack {
                            Text("#")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 25, alignment: .center)
                            Spacer()
                            Text("重量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("回数")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("RPE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 5)
                        .padding(.bottom, 2)
                        
                        List {
                            ForEach(Array(recordedSets.enumerated()), id: \.element.id) { index, setInfo in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.subheadline)
                                        .frame(width: 25, alignment: .center)
                                    Spacer()
                                    Text("\(String(format: "%.1f", setInfo.weight)) kg")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(setInfo.reps)回")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(setInfo.rpe != nil ? String(format: "%.1f", setInfo.rpe!) : "-")
                                        .font(.subheadline)
                                }
                            }
                            .onDelete(perform: deleteSet)
                        }
                        .frame(height: min(CGFloat(recordedSets.count) * 44.0, 200.0)) // リストの高さを調整（最大値を設定）
                        .listStyle(.plain) // シンプルなスタイル
                    }
                    
                    Spacer() // 残りのスペースを埋める
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 5)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(selectedWorkout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
    }

    func addSet() {
        let currentRpe = rpeOptions[selectedRpeIndex]
        let newSet = WorkoutSetInfo(weight: selectedWeight, reps: selectedReps, rpe: currentRpe)
        recordedSets.append(newSet)
        
        // iPhoneに送信処理
        sessionManager.sendWorkoutSetToPhone(setInfo: newSet, exerciseId: selectedWorkout.id, exerciseName: selectedWorkout.name)
        
        // 成功フィードバックを表示
        withAnimation {
            showingAddSuccess = true
        }
        
        // 新しいセットまでスクロール（少し遅延させて確実に追加後に実行）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                scrollProxy?.scrollTo(recordedSets.last?.id, anchor: .bottom)
            }
        }
        
        // 2秒後にフィードバックを非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingAddSuccess = false
            }
        }
    }

    func deleteSet(at offsets: IndexSet) {
        recordedSets.remove(atOffsets: offsets)
        // TODO: iPhoneに削除情報を送信する？ (今回は送信までなので一旦省略)
    }
}

#Preview {
    let dummyWorkout = WorkoutData(id: "preview-dummy-id", name: "ダミーベンチプレス")
    return NavigationView {
         WorkoutRecordingView(selectedWorkout: dummyWorkout)
             .environmentObject(WatchSessionManager.shared) // Previewにも必要
    }
}
