import SwiftUI

#if os(macOS)
import AppKit

struct FloatingOverlayView: View {
    var url: URL
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "safari.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text("Continuity")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Opening \(url.host ?? "URL")...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

class OverlayManager {
    static let shared = OverlayManager()
    
    private var window: NSWindow?
    
    func showOverlay(for url: URL) {
        if window == nil {
            let hostingController = NSHostingController(rootView: FloatingOverlayView(url: url))
            
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            win.contentViewController = hostingController
            win.isOpaque = false
            win.backgroundColor = .clear
            win.level = .floating
            win.ignoresMouseEvents = true
            
            if let screen = NSScreen.main {
                let x = (screen.frame.width - 300) / 2
                // Start below the screen
                win.setFrameOrigin(NSPoint(x: x, y: -100))
            }
            
            self.window = win
        } else {
            (self.window?.contentViewController as? NSHostingController<FloatingOverlayView>)?.rootView = FloatingOverlayView(url: url)
        }
        
        guard let win = self.window, let screen = NSScreen.main else { return }
        win.makeKeyAndOrderFront(nil)
        
        let x = (screen.frame.width - 300) / 2
        let y = screen.frame.origin.y + 100 // Final position
        
        // Animate in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().setFrameOrigin(NSPoint(x: x, y: y))
            win.animator().alphaValue = 1.0
        }) {
            // Wait 2 seconds, then animate out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    win.animator().setFrameOrigin(NSPoint(x: x, y: -100))
                    win.animator().alphaValue = 0.0
                }) {
                    win.orderOut(nil)
                }
            }
        }
    }
}
#endif
