import SwiftUI
import Domain // ExerciseEntity を使用するため

struct ExerciseCardView: View {
    let exercise: ExerciseEntity
    @State private var emoji: String = ""

    // 利用可能な絵文字のリスト（ポップで洗練された絵文字）
    private let emojis = [
        "🚀", "🌟", "✨", "🎉", "🎈", "🎯", "💡", "💎", "🏆", "🥇",
        "🎨", "🎵", "🎸", "🎮", "👾", "🤖", "🧠", "🦾", "👀", "👓",
        "🧑‍💻", "🧑‍🔬", "🧑‍🚀", "🦸", "🧙", "🧚", "🦄", "🦋", "🌈", "🌊",
        "🌋", "🌠", "🌌", "🪐", "🌍", "🧭", "🗺️", "🏰", "🗽", "🗿",
        "📈", "📉", "📊", "💻", "📱", "⌚", "💡", "🔋", "🔌", "⚙️",
        "🧪", "🧬", "🔬", "🔭", "📚", "✏️", "🖌️", "🖋️", "✂️", "📌",
        "📎", "🔑", "🔒", "🔓", "🔔", "📣", "💬", "💭", "🎯", "🏁"
    ]

    init(exercise: ExerciseEntity) {
        self.exercise = exercise
        // init内でランダムな絵文字を一度だけ選択する
        _emoji = State(initialValue: emojis.randomElement() ?? "✨") // デフォルト絵文字もポップなものに
    }

    var body: some View {
        HStack(spacing: 18) {
            Text(emoji)
                .font(.title2)
                .padding(.leading)

            Text(exercise.name)
                .font(.title3)
                .lineLimit(2) // 種目名が長い場合に2行まで表示
                .truncationMode(.tail)

            Spacer() // 右側にスペースを確保
        }
        .padding() // 内側のパディング
        .frame(maxWidth: .infinity, minHeight: 80) // 高さを設定し、横幅は最大に
        .background(Color(UIColor.secondarySystemGroupedBackground)) // 背景色
        .cornerRadius(12) // 角丸
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2) // 軽い影
    }
}
