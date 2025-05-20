import SwiftUI

struct WorkoutRecordingView: View {
    let selectedWorkout: WorkoutData // 選択された種目データを受け取る
    @StateObject private var sessionManager = WatchSessionManager.shared
    
    @State private var selectedWeight: Double = 50.0 // 初期値
    @State private var selectedReps: Int = 10 // 初期値
    @State private var selectedRpeIndex: Int = 0 // Pickerでの選択用。「なし」を含む
    @State private var recordedSets: [WorkoutSetInfo] = []
    @State private var showingAddSuccess: Bool = false // セット追加成功時のフィードバック用
    @State private var tabIndex = 0 // タブ選択用 (0: 入力画面, 1: セット一覧)
    
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
        TabView(selection: $tabIndex) {
            // 入力画面
            VStack() {
                // フォーム入力部分を横並び、ラベルと入力部分を縦並びに配置
                HStack(spacing: 8) {
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
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: 60, height: 70)
                        
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
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: 60, height: 70)
                        
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
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: 60, height: 70)
                        
                        Text(" ")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 20)
                
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
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.3), value: showingAddSuccess)
                
                Spacer()
            }
            .tag(0)
            
            // セット一覧画面
            VStack(spacing: 8) {
                HStack {
                    Text("記録済みセット")
                        .font(.headline)
                    Spacer()
                    Text("\(recordedSets.count)セット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.top, 5)
                
                if recordedSets.isEmpty {
                    Spacer()
                    Text("まだセットが記録されていません")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
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
                    .padding(.horizontal, 10)
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
                    .listStyle(.plain) // シンプルなスタイル
                }
            }
            .tag(1)
        }
        .tabViewStyle(.verticalPage)
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
        
        // セット追加時に自動的にセット一覧タブに切り替え
        if recordedSets.count == 1 {
            // 初めてのセット追加時のみ、少し遅延させてタブを切り替える
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    tabIndex = 1
                }
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
