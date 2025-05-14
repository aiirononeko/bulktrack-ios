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
            self.setNumber = response.setNo
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
                    recordSetViaAPI()
                } label: {
                    Text(isRecordingSet ? "記録中..." : "セットを記録する")
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
                        }
                        .font(.subheadline)
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
        self.uiRecordedSets = setsFromManager.map { UIRecordedSet(from: $0) }
        self.currentSet = String(self.uiRecordedSets.count + 1)
        print("SessionWorkoutView: Loaded \(self.uiRecordedSets.count) sets for current session exercise \(exercise.id). Next set: \(self.currentSet)")
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

        apiService.recordSet(sessionId: sessionId, setData: setData) { result in
            DispatchQueue.main.async {
                self.isRecordingSet = false
                switch result {
                case .success(let setResponse):
                    print("Set recorded successfully via API: \(setResponse)")
                    
                    self.sessionManager.addRecordedSet(setResponse, for: self.exercise.id)
                    self.loadCurrentSessionSets()
                    
                    self.weightInput = ""
                    self.repsInput = ""
                    self.rpeInput = ""
                    self.focusedField = .weight 
                    
                case .failure(let error):
                    print("Failed to record set via API: \(error.localizedDescription)")
                    self.recordingError = error.localizedDescription
                }
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
