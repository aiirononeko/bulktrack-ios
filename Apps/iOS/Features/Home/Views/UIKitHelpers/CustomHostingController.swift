import SwiftUI
import UIKit

class CustomHostingController<Content: View>: UIHostingController<Content>, UIScrollViewDelegate {

    private var navigationTitle: String
    private var scrollView: UIScrollView?

    init(rootView: Content, title: String) {
        self.navigationTitle = title
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.navigationTitle
        self.navigationItem.largeTitleDisplayMode = .automatic
        configureNavigationBarAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // ダークモード/ライトモードの切り替えを検出
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            configureNavigationBarAppearance()
        }
    }
    
    private func configureNavigationBarAppearance() {
        guard let navController = navigationController else { return }
        
        // ダークモード用の外観設定
        let darkAppearance = UINavigationBarAppearance()
        darkAppearance.configureWithOpaqueBackground()
        darkAppearance.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        
        // ライトモード用の外観設定
        let lightAppearance = UINavigationBarAppearance()
        lightAppearance.configureWithDefaultBackground()
        lightAppearance.backgroundColor = .white
        
        // 現在のカラースキームに応じて外観を適用
        let appearance = traitCollection.userInterfaceStyle == .dark ? darkAppearance : lightAppearance
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 初回またはレイアウト変更時にScrollViewを探してデリゲートを設定
        if scrollView == nil {
            findAndSetScrollViewDelegate(in: self.view)
        }
    }
    
    private func findAndSetScrollViewDelegate(in view: UIView) {
        if let uiScrollView = view as? UIScrollView {
            // SwiftUIのScrollViewが直接UIScrollViewとして現れる場合
            self.scrollView = uiScrollView
            // SwiftUIのScrollViewはデフォルトでdelegateが設定されていることがあるため、
            // 強制的に上書きすると問題が起きる可能性がある。
            // ただし、large titleの挙動のためには、ナビゲーションコントローラが
            // スクロールイベントを検知できるようにする必要がある。
            // UIKitの標準的なUINavigationControllerとUIScrollViewの組み合わせでは、
            // scrollView.delegate を設定しなくても large title は機能する。
            // UIHostingController内のSwiftUI ScrollViewとの連携が問題かもしれない。
            // ここでは明示的なdelegate設定は一旦保留し、他の要因を探る。
            // もし必要であれば、慎重にdelegateを設定する。
            print("UIScrollView found directly.")
            uiScrollView.delegate = self
            return
        }

        for subview in view.subviews {
            // SwiftUIのScrollViewは通常、直接のサブビューではない可能性がある。
            // より深い階層にあるかもしれない。
            if let hostingScrollView = findScrollViewInHierarchy(view: subview) {
                self.scrollView = hostingScrollView
                hostingScrollView.delegate = self
                print("UIScrollView found in hierarchy.")
                return
            }
        }
    }

    private func findScrollViewInHierarchy(view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = findScrollViewInHierarchy(view: subview) {
                return scrollView
            }
        }
        return nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // わずかでもスクロールされたかを判定するため、contentOffset.y が 0 より大きいかで判定します。
        // 完全に0の場合のみラージタイトルを表示し、それ以外はインラインタイトルにします。
        if scrollView.contentOffset.y > CGFloat.leastNonzeroMagnitude {
            if self.navigationItem.largeTitleDisplayMode != .never {
                // print("Switching to inline title") // デバッグログはコメントアウトまたは削除を推奨
                self.navigationItem.largeTitleDisplayMode = .never
            }
        } else {
            if self.navigationItem.largeTitleDisplayMode != .automatic {
                 // print("Switching to large title (automatic)") // デバッグログはコメントアウトまたは削除を推奨
                self.navigationItem.largeTitleDisplayMode = .automatic
            }
        }
    }
}
