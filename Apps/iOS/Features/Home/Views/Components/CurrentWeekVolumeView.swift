import SwiftUI
import Domain

struct CurrentWeekVolumeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme

    private let targetVolumeMultiplier: Double = 1.02

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .frame(minHeight: 300)
            } else if let data = viewModel.dashboardData {
                VStack(spacing: 0) {
                    HStack {
                        Text("今週のボリューム")
                            .font(.title2.bold())
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ZStack {
                        let startAngleDegrees = -40.0 + 180.0
                        let endAngleDegrees = 220.0 + 180.0
                        let sweepDegrees = (endAngleDegrees - startAngleDegrees + 360.0).truncatingRemainder(dividingBy: 360.0)

                        Circle()
                            .trim(from: 0.0, to: CGFloat(sweepDegrees / 360.0))
                            .stroke(style: StrokeStyle(lineWidth: 18.0, lineCap: .round, lineJoin: .round))
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                            .rotationEffect(Angle(degrees: startAngleDegrees))

                        let targetVolume = data.lastWeek.totalVolume * targetVolumeMultiplier
                        let progress = min(1.0, max(0.0, (targetVolume > 0 ? data.thisWeek.totalVolume / targetVolume : (data.thisWeek.totalVolume > 0 ? 1.0 : 0.0))))
                        Circle()
                            .trim(from: 0.0, to: CGFloat(progress * (sweepDegrees / 360.0)))
                            .stroke(style: StrokeStyle(lineWidth: 24.0, lineCap: .round, lineJoin: .round))
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                            .rotationEffect(Angle(degrees: startAngleDegrees))
                            .animation(.linear, value: progress)

                        VStack {
                            Text("今週の総ボリューム")
                                .font(.callout)
                                .foregroundColor(.gray)
                            Text("\(String(format: "%.0f", data.thisWeek.totalVolume)) kg")
                                .font(.system(size: 36, weight: .bold))
                        }
                    }
                    .frame(width: 228, height: 228)
                    .padding(.top, 36)

                    HStack(alignment: .center, spacing: 20) {
                        Spacer()
                        VStack {
                            Text("目標ボリューム")
                                .font(.callout)
                                .foregroundColor(.gray)
                            let targetVolume = data.lastWeek.totalVolume * targetVolumeMultiplier
                            Text("\(String(format: "%.0f", targetVolume)) kg")
                                .font(.system(size: 24, weight: .medium))
                        }
                        Spacer()
                        VStack {
                            Text("残りボリューム")
                                .font(.callout)
                                .foregroundColor(.gray)
                            let targetVolume = data.lastWeek.totalVolume * targetVolumeMultiplier
                            let remainingVolume = max(0, targetVolume - data.thisWeek.totalVolume)
                            Text("\(String(format: "%.0f", remainingVolume)) kg")
                                .font(.system(size: 24, weight: .medium))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 20)

            } else if let errorMessage = viewModel.errorMessage {
                Text("エラー: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
                    .frame(minHeight: 300)
            } else {
                Text("データを取得できませんでした。")
                    .frame(minHeight: 300)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
