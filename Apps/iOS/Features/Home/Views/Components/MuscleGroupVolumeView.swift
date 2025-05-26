import SwiftUI

struct MuscleGroupVolumeView: View {
    @Environment(\.colorScheme) var colorScheme
    let muscleGroupName: String
    let totalVolume: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(muscleGroupName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            Text("\(totalVolume, specifier: "%.1f") kg") // 小数点以下1桁まで表示
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(UIColor(white: 0.06, alpha: 1.0)) : .white)
        .cornerRadius(12)
    }
}

struct MuscleGroupVolumeView_Previews: PreviewProvider {
    static var previews: some View {
        MuscleGroupVolumeView(muscleGroupName: "胸", totalVolume: 12500.0)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
