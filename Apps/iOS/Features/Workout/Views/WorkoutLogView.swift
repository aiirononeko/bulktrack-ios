import SwiftUI

struct WorkoutLogView: View {
    @Environment(\.dismiss) var dismiss // 画面を閉じるために追加
    let exerciseName: String
    let exerciseId: String // ExerciseEntityのIDはUUIDなのでStringで受け取るのが適切かもしれません。元の型に合わせてください。

    var body: some View {
        // NavigationViewでラップしてタイトルと閉じるボタンを表示
        NavigationView {
            VStack {
            Text("筋トレ記録画面")
                .font(.largeTitle)
                .padding()
            
            Text("種目名: \(exerciseName)")
            Text("種目ID: \(exerciseId)")
            
            Spacer()
            // 今後の記録フォームなどをここに追加
            }
            .navigationTitle(exerciseName) // ナビゲーションバーのタイトルにも種目名を表示
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

struct WorkoutLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutLogView(exerciseName: "ベンチプレス", exerciseId: "sample-id-123")
        }
    }
}
