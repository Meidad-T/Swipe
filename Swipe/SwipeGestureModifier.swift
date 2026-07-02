import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
struct SwipeGestureModifier: ViewModifier {
    var onSwipeUp: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                SwipeGestureView(onSwipeUp: onSwipeUp)
            )
    }
}

struct SwipeGestureView: UIViewRepresentable {
    var onSwipeUp: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let swipeGesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        swipeGesture.direction = .up
        swipeGesture.numberOfTouchesRequired = 3
        view.addGestureRecognizer(swipeGesture)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeUp: onSwipeUp)
    }

    class Coordinator: NSObject {
        var onSwipeUp: () -> Void

        init(onSwipeUp: @escaping () -> Void) {
            self.onSwipeUp = onSwipeUp
        }

        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            if gesture.state == .recognized {
                onSwipeUp()
            }
        }
    }
}

extension View {
    func onThreeFingerSwipeUp(perform action: @escaping () -> Void) -> some View {
        self.modifier(SwipeGestureModifier(onSwipeUp: action))
    }
}
#endif
