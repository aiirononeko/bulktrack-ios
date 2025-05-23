import SwiftUI
import UIKit

struct CustomNavigationViewRepresentable<Content: View>: UIViewControllerRepresentable {
    
    let rootView: Content
    let title: String
    let configureNavController: (UINavigationController) -> Void

    init(title: String, @ViewBuilder content: () -> Content, configureNavController: @escaping (UINavigationController) -> Void = { _ in }) {
        self.rootView = content()
        self.title = title
        self.configureNavController = configureNavController
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let hostingController = CustomHostingController(rootView: rootView, title: title)
        let navController = UINavigationController(rootViewController: hostingController)
        navController.navigationBar.prefersLargeTitles = true // ★大きなタイトルを有効にする
        // hostingController.navigationItem.largeTitleDisplayMode = .automatic // これはCustomHostingController側で設定
        configureNavController(navController)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Update the hosting controller's root view if needed.
        if let hostingController = uiViewController.viewControllers.first as? CustomHostingController<Content> {
            hostingController.rootView = rootView
            // hostingController.navigationItem.title = title // タイトルが動的に変わる場合
        }
        // Re-apply navigation controller configuration if it can change
        // configureNavController(uiViewController)
    }
    
    // Coordinator can be added here if needed for delegate callbacks
}
