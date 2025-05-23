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
    @Published var showSuccessAlert = false
    
    private let createSetUseCase: CreateSetUseCaseProtocol
    private let exerciseId: UUID
    
    init(exerciseId: UUID, createSetUseCase: CreateSetUseCaseProtocol) {
        self.exerciseId = exerciseId
        self.createSetUseCase = createSetUseCase
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
        
        let result = await createSetUseCase.execute(request: request)
        
        switch result {
        case .success:
            clearForm()
            showSuccessAlert = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 入力値の検証
    private func validateInput() -> Bool {
        guard !weight.isEmpty,
              !reps.isEmpty,
              Double(weight) != nil,
              Int(reps) != nil else {
            errorMessage = "重量とレップ数を正しく入力してください"
            return false
        }
        
        if !rpe.isEmpty {
            guard let rpeValue = Double(rpe), (rpeValue >= 1 && rpeValue <= 10) else {
                errorMessage = "RPEは1〜10の間で入力してください"
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

        *: RPEを入力していただくことで、トレーニングの強度をより正確に記録できます。
        """
    }
}
