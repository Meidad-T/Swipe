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
                TouchTrackingView(onSwipeUp: onSwipeUp)
            )
    }
}

class CustomTouchView: UIView {
    var onSwipeUp: (() -> Void)?
    
    private var touchViews: [UITouch: UIView] = [:]
    private var initialTouchLocations: [UITouch: CGPoint] = [:]
    private let swipeThreshold: CGFloat = -100 // 100 points upwards
    private var hasTriggeredSwipe = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isMultipleTouchEnabled = true
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let circle = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            circle.center = location
            circle.layer.cornerRadius = 40
            circle.backgroundColor = UIColor(hue: CGFloat.random(in: 0...1), saturation: 0.8, brightness: 0.9, alpha: 0.6)
            circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.addSubview(circle)
            
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                circle.transform = .identity
            }, completion: nil)
            
            touchViews[touch] = circle
            initialTouchLocations[touch] = location
        }
        hasTriggeredSwipe = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !hasTriggeredSwipe else { return }
        
        var allMovingUp = true
        var averageDeltaY: CGFloat = 0
        var trackedTouchesCount = 0
        
        for touch in touches {
            guard let circle = touchViews[touch], let initialLoc = initialTouchLocations[touch] else { continue }
            let location = touch.location(in: self)
            circle.center = location
            
            let deltaY = location.y - initialLoc.y
            averageDeltaY += deltaY
            trackedTouchesCount += 1
            
            if deltaY > 0 {
                allMovingUp = false
            }
        }
        
        if trackedTouchesCount >= 3 && allMovingUp {
            let avg = averageDeltaY / CGFloat(trackedTouchesCount)
            if avg < swipeThreshold {
                hasTriggeredSwipe = true
                onSwipeUp?()
                
                // Animate out all circles
                for (_, circle) in touchViews {
                    UIView.animate(withDuration: 0.3, animations: {
                        circle.transform = CGAffineTransform(translationX: 0, y: -500)
                        circle.alpha = 0
                    }) { _ in
                        circle.removeFromSuperview()
                    }
                }
                touchViews.removeAll()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeTouches(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeTouches(touches)
    }
    
    private func removeTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            if let circle = touchViews[touch] {
                UIView.animate(withDuration: 0.2, animations: {
                    circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    circle.alpha = 0
                }) { _ in
                    circle.removeFromSuperview()
                }
                touchViews.removeValue(forKey: touch)
                initialTouchLocations.removeValue(forKey: touch)
            }
        }
    }
}

struct TouchTrackingView: UIViewRepresentable {
    var onSwipeUp: () -> Void

    func makeUIView(context: Context) -> CustomTouchView {
        let view = CustomTouchView(frame: .zero)
        view.onSwipeUp = onSwipeUp
        return view
    }

    func updateUIView(_ uiView: CustomTouchView, context: Context) {}
}

extension View {
    func onThreeFingerSwipeUp(perform action: @escaping () -> Void) -> some View {
        self.modifier(SwipeGestureModifier(onSwipeUp: action))
    }
}
#endif
