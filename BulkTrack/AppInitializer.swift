//import Foundation
//import SwiftUI // ObservableObjectのために必要
//
//final class AppInitializer: ObservableObject {
//    private let activationService = ActivationService()
//    private let apiService = APIService()
//
//    // アプリの初期化処理を実行
//    func initializeApp() {
//        print("AppInitializer: Initializing app...")
//        activationService.activateDeviceIfNeeded { [weak self] result in // selfへの弱参照を使用
//            guard let self = self else { return } // selfがnilの場合は何もしない
//            
//            // DispatchQueue.main.async を使ってメインスレッドで実行
//            DispatchQueue.main.async {
//                switch result {
//                case .success:
//                    print("AppInitializer: Activation process completed (or not needed).")
//                case .failure(let error):
//                    print("AppInitializer: Activation process failed: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//}
