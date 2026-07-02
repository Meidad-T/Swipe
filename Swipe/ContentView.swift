import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @State private var statusMessage: String = "Waiting for URL in clipboard"
    @State private var isPointingAtMac: Bool = false
    @State private var clipboardURL: String? = nil
    
    var body: some View {
        #if os(iOS)
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                HStack {
                    Spacer()
                    Button(action: {
                        SpatialTracker.shared.calibrateMacLocation()
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "location.north.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                Spacer()
                
                Image(systemName: "macbook.and.iphone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Spatial Continuity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if clipboardURL != nil {
                    Text("URL Ready in Clipboard")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Place 3 fingers anywhere and swipe up")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("Copy a link in Safari first")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(isPointingAtMac ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(isPointingAtMac ? "Pointing at Mac" : "Not pointing at Mac")
                        .font(.caption)
                        .foregroundColor(isPointingAtMac ? .green : .red)
                }
                
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 20)
                
                Spacer()
                Spacer()
            }
            .padding()
        }
        .onAppear {
            checkClipboard()
            // Poll for direction and clipboard changes
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.isPointingAtMac = SpatialTracker.shared.isPointingAtMac()
                self.checkClipboard()
            }
        }
        .onThreeFingerSwipeUp {
            sendURL()
        }
        #else
        Text("Mac Background Agent Running")
            .padding()
        #endif
    }
    
    #if os(iOS)
    private func checkClipboard() {
        if let string = UIPasteboard.general.string, let _ = URL(string: string) {
            if clipboardURL != string {
                clipboardURL = string
                statusMessage = "Ready to send"
            }
        } else {
            clipboardURL = nil
            statusMessage = "Waiting for URL in clipboard"
        }
    }
    
    private func sendURL() {
        guard let urlString = clipboardURL, let url = URL(string: urlString) else {
            statusMessage = "No URL to send"
            return
        }
        
        MultipeerManager.shared.send(url: url)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            statusMessage = "Sent!"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusMessage = "Ready to send"
        }
    }
    #endif
}

#Preview {
    ContentView()
}
