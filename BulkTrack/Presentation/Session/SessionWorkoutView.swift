// SessionWorkoutView.swift
// BulkTrack
//
// Created by Ryota Katada on 2025/05/10.
//

import SwiftUI

struct SessionWorkoutView: View {
    @Environment(\.colorScheme) var colorScheme // colorScheme を環境変数として追加
    let sessionId: String
    let exercise: Exercise 
    @Binding var isPresented: Bool
    @EnvironmentObject var sessionManager: SessionManager
    // UserSettingsServiceのインスタンスを取得
    private let userSettingsService = UserSettingsService.shared

    @State private var currentSet: String = "1"
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var rpeInput: String = ""
    
    @State private var isRecordingSet: Bool = false
    @State private var recordingError: String? = nil

    // 新しく追加: 前回のワークアウト記録表示用
    @State private var lastWorkoutDisplay: LastWorkoutSessionForExercise? = nil

    // ★ 編集中のセットを保持する状態変数を追加
    @State private var editingSet: UIRecordedSet? = nil

    // ★ 削除確認モーダル用の状態変数を追加
    @State private var showingDeleteConfirmModal: Bool = false
    @State private var setToDelete: UIRecordedSet? = nil

    // UI表示用の構造体
    struct UIRecordedSet: Identifiable { 
        let id: String 
        let setNumber: Int
        let weight: Double
        let reps: Int
        let rpe: Double?
        let completedAt: Date? 

        init(from response: WorkoutSetResponse) {
            self.id = response.id
            self.setNumber = response.setNumber
            self.weight = Double(response.weight) 
            self.reps = response.reps
            self.rpe = response.rpe != nil ? Double(response.rpe!) : nil
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.completedAt = formatter.date(from: response.performedAt)
        }
    }
    @State private var uiRecordedSets: [UIRecordedSet] = [] 

    @FocusState private var focusedField: Field?

    enum Field: Hashable { 
        case weight
        case reps
        case rpe 
    }

    // APIServiceのインスタンスも必要
    private let apiService = APIService()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 15) { // VStackのalignmentをleadingに変更
                
                // 前回の記録表示セクション
                if let lastWorkout = lastWorkoutDisplay, !lastWorkout.sets.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("前回の記録 (\(lastWorkout.recordedDate, style: .date))")
                            .font(.headline)
                            .padding(.bottom, 2)
                        ForEach(lastWorkout.sets) { setDetail in
                            Text(setDetail.displayString) // RecordedSetDetail に displayString を追加想定
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    Divider()
                }
                
                HStack {
                    Text("セット \(currentSet)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer() 
                }
                
                HStack(alignment: .top, spacing: 15) { 
                    VStack(alignment: .leading, spacing: 5) {
                        Text("重量(kg)")
                            .font(.caption)
                        TextField("例: 60", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minWidth: 0, maxWidth: .infinity) 
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("回数")
                            .font(.caption)
                        TextField("例: 10", text: $repsInput)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .reps)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("RPE")
                            .font(.caption)
                        TextField("例: 8.5", text: $rpeInput)
                            .keyboardType(.decimalPad) 
                            .focused($focusedField, equals: .rpe)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
                // .padding(.horizontal) // HStackにpaddingがあるのでVStackからは削除してもよいかも

                Button {
                    // ★ recordSetViaAPI を呼び出すか、updateSetViaAPI を呼び出すかを editingSet の状態で分岐
                    if editingSet == nil {
                        recordSetViaAPI()
                    } else {
                        updateSetViaAPI()
                    }
                } label: {
                    // ★ ボタンのラベルを編集中かどうかで変更
                    Text(isRecordingSet ? "処理中..." : (editingSet == nil ? "セットを記録する" : "セットを更新する"))
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white) // 文字色をモードに応じて変更
                }
                .buttonStyle(.borderedProminent) 
                .tint(Color.primary)
                .frame(maxWidth: .infinity) // ボタンを横幅いっぱいに
                // .padding(.top) // VStackのspacingで調整

                if let error = recordingError {
                    Text("記録エラー: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.vertical, 2)
                }

                List {
                    ForEach(uiRecordedSets) { set in
                        HStack {
                            Text("Set \(set.setNumber):")
                            Spacer()
                            Text("\(String(format: "%.1f", set.weight)) kg")
                            Spacer()
                            Text("\(set.reps) reps")
                            if let rpe = set.rpe {
                                Spacer()
                                Text("RPE \(String(format: "%.1f", rpe))")
                            }
                            Spacer() // ゴミ箱アイコン用のスペース
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    self.setToDelete = set
                                    self.showingDeleteConfirmModal = true
                                }
                        }
                        .font(.subheadline)
                        // ★ セットの行をタップした時の処理を追加
                        .contentShape(Rectangle()) // タップ領域を広げる
                        .onTapGesture {
                            self.editingSet = set
                            self.weightInput = String(format: "%.1f", set.weight)
                            self.repsInput = String(set.reps)
                            self.rpeInput = set.rpe != nil ? String(format: "%.1f", set.rpe!) : ""
                            self.currentSet = String(set.setNumber) // currentSetも更新
                            self.focusedField = .weight // フォーカスを重量入力に
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle(exercise.name ?? exercise.canonicalName) 
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { 
                    Button {
                        isPresented = false 
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                 .font(.caption)
                            Text("他の種目を選ぶ")
                                 .font(.caption)
                        }
                    }
                    .tint(Color.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer() 
                    Button("完了") {
                        focusedField = nil 
                    }
                }
            }
            // ★ 削除確認ダイアログを追加
            .confirmationDialog(
                "セットを削除",
                isPresented: $showingDeleteConfirmModal,
                presenting: setToDelete
            ) { setToBeDeleted in
                Button("削除", role: .destructive) {
                    deleteSetConfirmed(set: setToBeDeleted)
                }
                Button("キャンセル", role: .cancel) {}
            } message: { setToBeDeleted in
                Text("「Set \(setToBeDeleted.setNumber): \(String(format: "%.1f", setToBeDeleted.weight)) kg x \(setToBeDeleted.reps) reps」を完全に削除しますか？この操作は取り消せません。")
            }
            .onAppear {
                loadCurrentSessionSets() // メソッド名を変更して明確化
                loadLastWorkoutRecord()  // 前回の記録をロード
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.focusedField = .weight 
                }
            }
            .onDisappear { // ビューが非表示になるタイミングで実行
                let allSetsForThisExerciseInSession = self.sessionManager.getRecordedSets(for: self.exercise.id)
                // セットが記録されている場合のみ保存処理を行う
                if !allSetsForThisExerciseInSession.isEmpty {
                    self.userSettingsService.saveLastWorkoutSession(
                        for: self.exercise,
                        with: self.sessionId,
                        setsFromCurrentSession: allSetsForThisExerciseInSession
                    )
                    print("SessionWorkoutView: Saved last workout session on disappear.")
                }
            }
        }
    }

    // メソッド名を変更: loadCurrentSessionSets
    private func loadCurrentSessionSets() {
        let setsFromManager = sessionManager.getRecordedSets(for: exercise.id)
        self.uiRecordedSets = setsFromManager.map { UIRecordedSet(from: $0) }.sorted { $0.setNumber < $1.setNumber } // setNumberでソート
        
        // editingSetがnilの場合（新規入力モード）のみ、次のセット番号を計算
        if editingSet == nil {
            self.currentSet = String(self.uiRecordedSets.count + 1)
        }
        // 編集モードではなくなった場合（クリアされた場合）も次のセット番号を再計算
        // このロジックは recordSetViaAPI や updateSetViaAPI の成功後に移動した方が良いかも
        
        print("SessionWorkoutView: Loaded \(self.uiRecordedSets.count) sets for current session exercise \(exercise.id). Current input set number: \(self.currentSet)")
    }

    // 新しく追加: 前回のワークアウト記録をロードするメソッド
    private func loadLastWorkoutRecord() {
        self.lastWorkoutDisplay = userSettingsService.getLastWorkoutSession(for: exercise.id, excludingCurrentSessionId: self.sessionId)
        if let lastWorkout = self.lastWorkoutDisplay {
            print("SessionWorkoutView: Loaded last workout record (session: \(lastWorkout.sessionId)) for exercise \(exercise.id) with \(lastWorkout.sets.count) sets from \(lastWorkout.recordedDate).")
        } else {
            print("SessionWorkoutView: No last workout record found for exercise \(exercise.id) (excluding current session \(self.sessionId)).")
        }
    }

    private func recordSetViaAPI() { 
        guard let weight = Float(weightInput), 
              let reps = Int(repsInput),
              let setNum = Int(currentSet) else {
            recordingError = "重量、回数、またはセット番号の入力が無効です。"
            return
        }
        let rpeValue = !rpeInput.isEmpty ? Float(rpeInput) : nil 
        if !rpeInput.isEmpty && rpeValue == nil {
            recordingError = "RPEの入力形式が無効です。"
            return
        }

        let setData = WorkoutSetCreate(exerciseId: exercise.id,
                                       setNumber: setNum, 
                                       weight: weight, 
                                       reps: reps, 
                                       rpe: rpeValue)

        isRecordingSet = true
        recordingError = nil

        apiService.recordSet(sessionId: sessionId, setData: setData) { result in // 'addSetToSession' を 'recordSet' に修正
            DispatchQueue.main.async {
                self.isRecordingSet = false
                switch result {
                case .success(let setResponse):
                    print("Set recorded successfully via API: \(setResponse)")
                    
                    self.sessionManager.addRecordedSet(setResponse, for: self.exercise.id)
                    self.clearInputsAndResetToNextSet() // 入力クリアと次のセットへの準備
                    
                case .failure(let error):
                    print("Failed to record set via API: \(error.localizedDescription)")
                    self.recordingError = error.localizedDescription
                }
            }
        }
    }

    // ★ セット更新処理のメソッドを新しく追加
    private func updateSetViaAPI() {
        guard let editingSet = self.editingSet, // 編集中のセットがあることを確認
              let weight = Float(weightInput),
              let reps = Int(repsInput) else {
            recordingError = "重量または回数の入力が無効です。"
            return
        }
        let rpeValue = !rpeInput.isEmpty ? Float(rpeInput) : nil
        if !rpeInput.isEmpty && rpeValue == nil {
            recordingError = "RPEの入力形式が無効です。"
            return
        }

        // SetUpdate オブジェクトを作成
        // executedAt はサーバー側で更新されるか、または現在のものを送信しない設計の場合nil
        // もしクライアント側でexecutedAtを更新する必要がある場合は、ここでDate().ISO8601Format()などをセット
        let updateData = SetUpdate(
            exerciseId: nil, // exerciseId は通常変更しないのでnil。もし変更可能なら値を入れる
            weight: weight,
            reps: reps,
            rpe: rpeValue,
            notes: nil, // ノート機能が追加されれば入力値を入れる
            performedAt: nil // 必要に応じて設定 (executedAt から変更)
        )

        isRecordingSet = true
        recordingError = nil

        apiService.updateSet(sessionId: sessionId, setId: editingSet.id, setData: updateData) { result in
            DispatchQueue.main.async {
                self.isRecordingSet = false
                switch result {
                case .success(let updatedSetResponse):
                    print("Set updated successfully via API: \(updatedSetResponse)")
                    self.sessionManager.updateRecordedSet(updatedSetResponse, for: self.exercise.id)
                    self.clearInputsAndResetToNextSet() // 入力クリアと次のセットへの準備

                case .failure(let error):
                    print("Failed to update set via API: \(error.localizedDescription)")
                    self.recordingError = error.localizedDescription
                }
            }
        }
    }
    
    // ★ 入力フィールドをクリアし、次のセット入力状態にリセットするヘルパーメソッド
    private func clearInputsAndResetToNextSet() {
        self.editingSet = nil // 編集モードを解除
        self.weightInput = ""
        self.repsInput = ""
        self.rpeInput = ""
        self.loadCurrentSessionSets() // セットリストと次のセット番号を再読み込み/再計算
        self.focusedField = .weight
        self.recordingError = nil
    }

    // ★ セット削除実行メソッドを追加
    private func deleteSetConfirmed(set: UIRecordedSet) {
        guard let currentSessionId = sessionManager.currentSessionId else {
            print("SessionWorkoutView: Error - currentSessionId is nil, cannot delete set.")
            self.recordingError = "セッションIDが見つかりません。"
            return
        }

        isRecordingSet = true // 既存のローディング状態を流用
        recordingError = nil

        apiService.deleteSet(sessionId: currentSessionId, setId: set.id) { result in
            DispatchQueue.main.async {
                self.isRecordingSet = false
                switch result {
                case .success:
                    print("Set \(set.id) deleted successfully from API.")
                    self.sessionManager.deleteRecordedSet(setId: set.id, for: self.exercise.id)
                    // 編集中のセットが削除されたセットだった場合、編集モードを解除
                    if self.editingSet?.id == set.id {
                        self.editingSet = nil
                    }
                    self.clearInputsAndResetToNextSet() // UIをリフレッシュ
                    
                case .failure(let error):
                    print("Failed to delete set \(set.id) from API: \(error.localizedDescription)")
                    self.recordingError = "セットの削除に失敗しました: \(error.localizedDescription)"
                }
                self.setToDelete = nil // 削除対象をクリア
            }
        }
    }
}

// Preview
struct SessionWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let previewExercise = Exercise(
            id: "exercise-1",
            canonicalName: "ベンチプレス",
            locale: "ja",
            name: "ベンチプレス",
            aliases: nil,
            isOfficial: true,
            lastUsedAt: nil
        )
        
        SessionWorkoutView(
            sessionId: "preview-session-123",
            exercise: previewExercise, 
            isPresented: .constant(true)
        )
        .environmentObject(SessionManager()) 
    }
}
