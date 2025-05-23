import SwiftUI
import Domain

struct WorkoutLogView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WorkoutLogViewModel
    @FocusState private var focusedField: Field?
    @State private var showRPEHelp = false
    
    let exerciseName: String
    
    enum Field: CaseIterable {
        case weight, reps, rpe
    }
    
    init(exerciseName: String, exerciseId: UUID, createSetUseCase: CreateSetUseCaseProtocol) {
        self.exerciseName = exerciseName
        self._viewModel = StateObject(wrappedValue: WorkoutLogViewModel(exerciseId: exerciseId, createSetUseCase: createSetUseCase))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // メイン入力フォーム
                ScrollView {
                    VStack(spacing: 24) {
                        // 重量とレップ数の横並びフォーム
                        HStack(spacing: 16) {
                            InputField(
                                title: "重量 (kg)",
                                text: $viewModel.weight,
                                keyboardType: .decimalPad,
                                focused: $focusedField,
                                field: .weight
                            )
                            
                            InputField(
                                title: "回数",
                                text: $viewModel.reps,
                                keyboardType: .numberPad,
                                focused: $focusedField,
                                field: .reps
                            )
                        }
                        
                        // RPE入力（ヘルプ付き）
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("RPE")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Button(action: {
                                    showRPEHelp = true
                                }) {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                            
                            TextField("1〜10で評価", text: $viewModel.rpe)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .rpe)
                        }
                        
//                        // メモ入力
//                        VStack(alignment: .leading, spacing: 8) {
//                            HStack {
//                                Text("メモ（任意）")
//                                    .font(.headline)
//                                    .foregroundColor(.primary)
//                                Spacer()
//                            }
//                            
//                            TextField("メモを入力", text: $viewModel.memo, axis: .vertical)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .lineLimit(3...6)
//                                .focused($focusedField, equals: .memo)
//                        }
                        
                        // エラーメッセージ
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer(minLength: 100) // キーボード分の余白
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // セット登録ボタン（下部固定）
                VStack(spacing: 12) {
                    Divider()
                    
                    Button(action: {
                        Task {
                            await viewModel.saveSet()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(viewModel.isLoading ? "登録中..." : "セットを登録")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primary)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                // 画面表示時に最初のフィールドにフォーカス
                focusedField = .weight
            }
            .alert("RPE (主観的運動強度)", isPresented: $showRPEHelp) {
                Button("OK") { }
            } message: {
                Text(viewModel.rpeHelpText)
            }
            .alert("セット登録完了", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("セットが正常に登録されました")
            }
        }
    }
}

// MARK: - InputField Component
struct InputField: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focused: WorkoutLogView.Field?
    let field: WorkoutLogView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("0", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .focused($focused, equals: field)
                .multilineTextAlignment(.center)
                .font(.title2)
        }
    }
}
