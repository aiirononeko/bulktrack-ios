import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var selectedTab = 0
    private let tabTitles = ["今週のボリューム", "週次ボリュームの推移", "週次平均RMの推移"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    CurrentWeekVolumeView(viewModel: viewModel)
                        .tag(0)
                    WeeklyVolumeTrendView(viewModel: viewModel)
                        .tag(1)
                    WeeklyAverageRMView(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 標準のインジケータは非表示
                .frame(height: UIScreen.main.bounds.height * 4 / 9)
                .background(colorScheme == .dark ? Color.black : Color.white)

                // 自作ドットインジケータ
                DotIndicatorView(count: tabTitles.count, selectedIndex: $selectedTab)
                    .padding(.vertical, 18)

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView("データを取得中...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("エラー: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if let dashboardData = viewModel.dashboardData {
                        Text("部位別ボリューム")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        // 部位別ボリュームカード
                        let currentWeekMuscleVolumes = dashboardData.currentWeekMuscleGroupVolumes
                        VStack(spacing: 16) {
                            ForEach(currentWeekMuscleVolumes) { volumeData in
                                MuscleGroupVolumeView(muscleGroupName: volumeData.muscleGroupName, totalVolume: volumeData.totalVolume)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background((colorScheme == .dark ? .black : Color(uiColor: .systemGray6)).ignoresSafeArea())
            .navigationTitle("ホーム")
            .onAppear {
                print("[HomeView] onAppear - データを自動取得します。")
                viewModel.fetchDashboardData()
            }
        }
    }
}

// Preview Provider (Optional, for development)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
    }
}
