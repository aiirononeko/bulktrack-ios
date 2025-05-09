// SessionWorkoutView.swift
// BulkTrack
//
// Created by Ryota Katada on 2025/05/10.
//

import SwiftUI

struct SessionWorkoutView: View {
    let sessionId: String
    let exercise: Exercise 
    @Binding var isPresented: Bool
    @EnvironmentObject var sessionManager: SessionManager
    private let apiService = APIService() // APIServiceのインスタンス (本来はDI推奨)

    @State private var currentSet: String = "1" 
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var rpeInput: String = "" 
    
    @State private var isRecordingSet: Bool = false
    @State private var recordingError: String? = nil

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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) { 
                Text("セット \(currentSet)") 
                    .font(.title2)
                    .fontWeight(.semibold)
                
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
                .padding(.horizontal) 

                Button(isRecordingSet ? "記録中..." : "セットを記録する") {
                    recordSetViaAPI()
                }
                .buttonStyle(.bordered)
                .padding(.top)
                .disabled(isRecordingSet)

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
                            // 必要であればcompletedAtも表示
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("一時中断") { 
                        isPresented = false 
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer() 
                    Button("完了") {
                        focusedField = nil 
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.focusedField = .weight 
                }
            }
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
                    let newUIRecordedSet = UIRecordedSet(from: setResponse)
                    self.uiRecordedSets.append(newUIRecordedSet)
                    
                    if let nextSet = Int(self.currentSet) {
                        self.currentSet = String(nextSet + 1)
                    }
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
