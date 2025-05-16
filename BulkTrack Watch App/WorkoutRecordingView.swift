import SwiftUI

struct WorkoutRecordingView: View {
    let selectedWorkout: WorkoutData // 選択された種目データを受け取る
    @StateObject private var sessionManager = WatchSessionManager.shared

    @State private var selectedWeight: Double = 50.0 // 初期値
    @State private var selectedReps: Int = 10 // 初期値
    @State private var selectedRpeIndex: Int = 0 // Pickerでの選択用。「なし」を含む
    @State private var recordedSets: [WorkoutSetInfo] = []

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
            VStack(spacing: 12) {
                // 重量ピッカー
                HStack {
                    Text("重量 (kg)")
                    Spacer()
                    Picker("重量", selection: $selectedWeight) {
                        ForEach(weightRange, id: \.self) { weight in
                            Text(String(format: "%.1f", weight)).tag(weight)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100) // 幅を調整
                }

                // レップピッカー
                HStack {
                    Text("レップ数")
                    Spacer()
                    Picker("レップ数", selection: $selectedReps) {
                        ForEach(repsRange, id: \.self) { reps in
                            Text("\(reps) 回").tag(reps)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80) // 幅を調整
                }
                
                // RPEピッカー
                HStack {
                    Text("RPE")
                    Spacer()
                    Picker("RPE", selection: $selectedRpeIndex) {
                        ForEach(0..<rpeDisplayOptions.count, id: \.self) { index in
                            Text(rpeDisplayOptions[index]).tag(index)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80) // 幅を調整
                }

                Button(action: addSet) {
                    Text("セット追加")
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 5)

                if !recordedSets.isEmpty {
                    Divider()
                    Text("記録済みセット")
                        .font(.subheadline)
                    List {
                        ForEach(recordedSets) { setInfo in
                            HStack {
                                Text("\(String(format: "%.1f", setInfo.weight)) kg")
                                Spacer()
                                Text("\(setInfo.reps) Reps")
                                Spacer()
                                Text(setInfo.rpe != nil ? String(format: "RPE %.1f", setInfo.rpe!) : "RPE N/A")
                            }
                        }
                        .onDelete(perform: deleteSet)
                    }
                    .frame(height: CGFloat(recordedSets.count) * 45.0) // リストの高さを動的に調整
                    .listStyle(.plain) // シンプルなスタイル
                }
                
                Spacer() // 残りのスペースを埋める
            }
        }
        .padding()
        .navigationTitle(selectedWorkout.name) // ナビゲーションバーのタイトル
    }

    func addSet() {
        let currentRpe = rpeOptions[selectedRpeIndex]
        let newSet = WorkoutSetInfo(weight: selectedWeight, reps: selectedReps, rpe: currentRpe)
        recordedSets.append(newSet)
        
        // TODO: iPhoneに送信処理を追加
        sessionManager.sendWorkoutSetToPhone(setInfo: newSet, exerciseId: selectedWorkout.id, exerciseName: selectedWorkout.name)
        
        // 入力値をリセットまたは前の値を維持するかはUXによる
        // selectedWeight = 50.0 // 例: 初期値に戻す
        // selectedReps = 10
        // selectedRpeIndex = 0
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
