//
//  WorkoutLogViewModel.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/23.
//

import SwiftUI
import Foundation
import Domain

@MainActor
final class WorkoutLogViewModel: ObservableObject {
    @Published var weight: String = ""
    @Published var reps: String = ""
    @Published var rpe: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Workout History State
    @Published var previousWorkout: WorkoutHistoryEntity? = nil
    @Published var todaysSets: [LocalWorkoutSetEntity] = []
    @Published var isLoadingHistory = false
    
    private let saveWorkoutSetUseCase: SaveWorkoutSetUseCaseProtocol
    private let getWorkoutHistoryUseCase: GetWorkoutHistoryUseCaseProtocol
    private let deleteSetUseCase: DeleteSetUseCaseProtocol
    private let exerciseId: UUID
    private let exerciseName: String
    
    // Toast Manager
    let toastManager = ToastManager()
    
    init(
        exerciseId: UUID,
        exerciseName: String,
        saveWorkoutSetUseCase: SaveWorkoutSetUseCaseProtocol,
        getWorkoutHistoryUseCase: GetWorkoutHistoryUseCaseProtocol,
        deleteSetUseCase: DeleteSetUseCaseProtocol
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.saveWorkoutSetUseCase = saveWorkoutSetUseCase
        self.getWorkoutHistoryUseCase = getWorkoutHistoryUseCase
        self.deleteSetUseCase = deleteSetUseCase
    }
    
    /// 履歴を読み込み
    func loadWorkoutHistory() async {
        isLoadingHistory = true
        
        let result = await getWorkoutHistoryUseCase.execute(exerciseId: exerciseId)
        
        switch result {
        case .success(let data):
            previousWorkout = data.previousWorkout
            todaysSets = data.todaysSets
        case .failure(let error):
            print("[WorkoutLogViewModel] Failed to load history: \(error)")
        }
        
        isLoadingHistory = false
    }
    
    /// セット登録処理
    func saveSet() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let request = CreateSetRequest(
            exerciseId: exerciseId,
            weight: Double(weight) ?? 0,
            reps: Int(reps) ?? 0,
            rpe: rpe.isEmpty ? nil : Double(rpe),
            performedAt: Date()
        )
        
        let result = await saveWorkoutSetUseCase.execute(request: request, exerciseName: exerciseName)
        
        switch result {
        case .success:
            clearForm()
            // トーストメッセージを表示（アラートは無効化）
            toastManager.showSuccessToast(message: "セットの記録が完了しました。\nインターバルタイマーを起動します。", duration: 2.0)
            // 履歴を再読み込み
            await loadWorkoutHistory()
        case .failure(let error):
            errorMessage = error.localizedDescription
            toastManager.showErrorToast(message: "セットの登録に失敗しました")
        }
        
        isLoading = false
    }
    
    /// 入力値の検証
    private func validateInput() -> Bool {
        guard !weight.isEmpty,
              !reps.isEmpty,
              Double(weight) != nil,
              Int(reps) != nil else {
            toastManager.showErrorToast(message: "重量とレップ数を正しく入力してください")
            return false
        }
        
        if !rpe.isEmpty {
            guard let rpeValue = Double(rpe), (rpeValue >= 1 && rpeValue <= 10) else {
                toastManager.showErrorToast(message: "RPEは1〜10の間で入力してください")
                return false
            }
        }
        
        return true
    }
    
    /// フォームをクリア
    private func clearForm() {
        weight = ""
        reps = ""
        rpe = ""
    }
    
    /// RPEのヘルプテキスト
    var rpeHelpText: String {
        """
        RPE (Rate of Perceived Exertion)
        主観的運動強度。1〜10で評価
        10: 限界、これ以上できない
        9: あと1レップできるかも
        8: あと2レップできそう
        7: あと3レップできそう

        RPEを入力していただくことで、トレーニングの強度をより正確に記録できます。
        """
    }
    
    // MARK: - Computed Properties
    
    /// 今日のセット数
    var todaysSetCount: Int {
        todaysSets.count
    }
    
    /// 前回ワークアウトの表示テキスト
    var previousWorkoutText: String {
        guard let previous = previousWorkout else {
            return "前回の記録はありません"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let dateString = formatter.string(from: previous.performedAt)
        
        return "\(dateString) - \(previous.sets.count)セット"
    }
    
    /// 今日のボリューム（重量×回数の合計）
    var todaysVolume: Double {
        todaysSets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
    
    /// 前回のボリューム
    var previousVolume: Double {
        guard let previous = previousWorkout else { return 0 }
        return previous.sets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
    
    /// セット削除処理
    func deleteSet(_ set: LocalWorkoutSetEntity) async {
        isLoading = true
        errorMessage = nil
        
        // APIからセットを削除
        let result = await deleteSetUseCase.execute(setId: set.id)
        
        switch result {
        case .success:
            toastManager.showSuccessToast(message: "セットを削除しました", duration: 2.0)
            
            // 履歴を再読み込み（これによりセット番号が自動的に再計算される）
            await loadWorkoutHistory()
        case .failure(let error):
            errorMessage = error.localizedDescription
            toastManager.showErrorToast(message: "セットの削除に失敗しました")
        }
        
        isLoading = false
    }
}
