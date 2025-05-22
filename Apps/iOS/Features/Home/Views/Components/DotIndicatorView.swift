import SwiftUI

struct DotIndicatorView: View {
    let count: Int
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(selectedIndex == index ? Color.primary : Color(UIColor.systemGray4))
                    .frame(width: 7, height: 7)
                    .onTapGesture {
                        selectedIndex = index
                    }
            }
        }
    }
}

struct DotIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        DotIndicatorView(count: 3, selectedIndex: .constant(0))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
