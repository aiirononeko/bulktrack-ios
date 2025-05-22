import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationView {
            Text("トレーニング履歴")
                .navigationTitle("履歴")
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
