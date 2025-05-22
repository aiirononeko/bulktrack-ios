import SwiftUI

struct ArticlesView: View {
    var body: some View {
        NavigationView {
            Text("コラム")
                .navigationTitle("コラム")
        }
    }
}

struct ArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
}
