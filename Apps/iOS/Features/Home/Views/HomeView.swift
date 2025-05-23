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
        CustomNavigationViewRepresentable(title: "ホーム") {
            ZStack {
                (colorScheme == .dark ? Color(UIColor(white: 0.12, alpha: 1.0)) : Color(UIColor.systemGray6))
                
                ScrollView {
                    VStack(spacing: 0) {
                        TabView(selection: $selectedTab) {
                            CurrentWeekVolumeView(viewModel: viewModel)
                                .tag(0)
                            WeeklyVolumeTrendView(viewModel: viewModel)
                                .tag(1)
                            WeeklyAverageRMView(viewModel: viewModel)
                                .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: UIScreen.main.bounds.height * 4 / 9)
                        .background(colorScheme == .dark ? Color(UIColor(white: 0.06, alpha: 1.0)) : Color.white)
                        
                        VStack {
                            DotIndicatorView(count: tabTitles.count, selectedIndex: $selectedTab)
                                .padding(.vertical, 18)
                        }
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? Color(UIColor(white: 0.12, alpha: 1.0)) : Color(UIColor.systemGray6))
                        
                        VStack(spacing: 0) {
                            if viewModel.isLoading {
                                ProgressView("データを取得中...")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if let errorMessage = viewModel.errorMessage {
                                Text("エラー: \(errorMessage)")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if let dashboardData = viewModel.dashboardData {
                                Text("部位別ボリューム")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                                
                                let currentWeekMuscleVolumes = dashboardData.currentWeekMuscleGroupVolumes
                                VStack(spacing: 16) {
                                    ForEach(currentWeekMuscleVolumes) { volumeData in
                                        MuscleGroupVolumeView(muscleGroupName: volumeData.muscleGroupName, totalVolume: volumeData.totalVolume)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .onAppear {
                    print("[HomeView] onAppear - データを自動取得します。")
                    viewModel.fetchDashboardData()
                }
            }
        }
    }
}

// Preview Provider (Optional, for development)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
    }
}
