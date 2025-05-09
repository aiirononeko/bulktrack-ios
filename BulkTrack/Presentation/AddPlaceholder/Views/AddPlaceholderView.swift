//
//  AddPlaceholderView.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/09.
//

import SwiftUI

struct AddPlaceholderView: View {
    // このビューはモーダルとして表示されるため、
    // 独自のモーダル表示状態や.onAppearでの処理は不要になります。
    @State private var selectionType: SelectionType = .individual // 選択状態を保持

    // 選択肢を定義するenum
    enum SelectionType: String, CaseIterable, Identifiable {
        case individual = "種目から選ぶ"
        case menu = "メニューから選ぶ"
        var id: String { self.rawValue }
    }

    var body: some View {
        // ここにモーダルとして表示したい内容を記述します。
        // 例として、以前のSampleModalViewのようなシンプルなTextを表示します。
        NavigationView { // モーダル内でナビゲーションが必要な場合など
            VStack(spacing: 10) {
                Picker("選択方法", selection: $selectionType) {
                    ForEach(SelectionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // 選択に応じて表示するコンテンツ
                switch selectionType {
                case .individual:
                    VStack(alignment: .leading) {
                        Text("よく使う種目")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                WorkoutItemCard(itemName: "ベンチプレス")
                                WorkoutItemCard(itemName: "スクワット")
                                WorkoutItemCard(itemName: "デッドリフト")
                                WorkoutItemCard(itemName: "懸垂")
                                // 他の種目カードも同様に追加可能
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 120) // ScrollViewの高さを指定

                        Spacer() // 残りのスペースを埋める
                    }
                case .menu:
                    Text("メニュー選択のUIをここに配置")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer() // 下部のスペースを確保し、コンテンツを上部に寄せる
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("トレーニングを開始する")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                }
            }
        }
    }
}

// AddPlaceholderView の struct の外に、WorkoutItemCard を定義します。
// もし別のファイルで共通化するなら、そちらに移動してください。
struct WorkoutItemCard: View {
    // let iconName: String // iconName プロパティを削除またはコメントアウト
    let itemName: String

    var body: some View {
        VStack {
            // TODO: 将来的には各アイテムに対応するアセットのアイコンを動的に表示する
            Image(systemName: "figure.strengthtraining.traditional") // 固定のアイコン
                .font(.largeTitle)
                .foregroundColor(.black) // アイコンの色を黒に変更
                .frame(height: 50)
            Text(itemName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(width: 100, height: 100)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray, lineWidth: 1)
        )
    }
}

#Preview {
    AddPlaceholderView()
}
