import SwiftUI

struct StartWorkoutSheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                Picker("種目選択", selection: $selectedTab) {
                    Text("最近行った種目").tag(0)
                    Text("すべての種目").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // TODO: 各タブに対応するコンテンツをここに表示
                if selectedTab == 0 {
                    Text("最近行った種目のリスト") // Placeholder
                } else {
                    Text("すべての種目のリスト") // Placeholder
                }

                Spacer()
            }
            .navigationTitle("トレーニングを開始する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    StartWorkoutSheetView()
}
