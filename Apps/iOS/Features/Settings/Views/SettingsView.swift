import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("アプリ設定")
                .navigationTitle("設定")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
