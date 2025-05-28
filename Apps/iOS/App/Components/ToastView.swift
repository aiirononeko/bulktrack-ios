import SwiftUI

// MARK: - Toast Message Model
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    enum ToastType {
        case success
        case info
        case warning
        case error
        
        var backgroundColor: Color {
            switch self {
            case .success:
                return Color.green
            case .info:
                return Color.blue
            case .warning:
                return Color.orange
            case .error:
                return Color.red
            }
        }
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .error:
                return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: ToastMessage
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.type.icon)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
            
            Text(message.message)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(message.type.backgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .opacity(isPresented ? 1 : 0)
        .scaleEffect(isPresented ? 1 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
    }
}

// MARK: - Toast Manager
@MainActor
class ToastManager: ObservableObject {
    @Published var currentToast: ToastMessage?
    @Published var isToastPresented = false
    
    private var toastQueue: [ToastMessage] = []
    private var isProcessingQueue = false
    
    func showToast(message: String, type: ToastMessage.ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = ToastMessage(message: message, type: type, duration: duration)
        toastQueue.append(toast)
        processQueueIfNeeded()
    }
    
    func showSuccessToast(message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .success, duration: duration)
    }
    
    func showInfoToast(message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .info, duration: duration)
    }
    
    func showWarningToast(message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .warning, duration: duration)
    }
    
    func showErrorToast(message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .error, duration: duration)
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue, !toastQueue.isEmpty else { return }
        
        isProcessingQueue = true
        let nextToast = toastQueue.removeFirst()
        
        currentToast = nextToast
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isToastPresented = true
        }
        
        // トースト表示時間後に非表示にする
        DispatchQueue.main.asyncAfter(deadline: .now() + nextToast.duration) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.isToastPresented = false
            }
            
            // アニメーション完了後に次のトーストを処理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentToast = nil
                self.isProcessingQueue = false
                self.processQueueIfNeeded()
            }
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        
                        if let toast = toastManager.currentToast {
                            ToastView(message: toast, isPresented: $toastManager.isToastPresented)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20) // ステータスバー + ナビゲーションエリアを避ける
                    
                    Spacer()
                },
                alignment: .top
            )
    }
}

// MARK: - View Extension
extension View {
    func toast(manager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: manager))
    }
}