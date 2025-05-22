import SwiftUI

struct MuscleGroupVolumeView: View {
    let muscleGroupName: String
    let totalVolume: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(muscleGroupName)
                .font(.headline)
            Text("今週のボリューム: \(totalVolume, specifier: "%.1f") kg") // 小数点以下1桁まで表示
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MuscleGroupVolumeView_Previews: PreviewProvider {
    static var previews: some View {
        MuscleGroupVolumeView(muscleGroupName: "胸", totalVolume: 12500.0)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
