import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var statusMessage: String = "Ready to send"
    @State private var isPointingAtMac: Bool = false
    
    var body: some View {
        #if os(iOS)
        VStack(spacing: 30) {
            Image(systemName: "arrow.up.and.person.rectangle.portrait")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("Spatial Continuity")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Paste a URL and point your phone at the Mac. Then swipe up with 3 fingers.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("URL to send", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Circle()
                    .fill(isPointingAtMac ? Color.green : Color.red)
                    .frame(width: 15, height: 15)
                
                Text(isPointingAtMac ? "Pointing at Mac" : "Not pointing at Mac")
                    .foregroundColor(isPointingAtMac ? .green : .red)
            }
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkClipboard()
            // Poll for direction
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.isPointingAtMac = SpatialTracker.shared.isPointingAtMac()
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
            urlString = string
            statusMessage = "Found URL in clipboard!"
        }
    }
    
    private func sendURL() {
        guard let url = URL(string: urlString) else {
            statusMessage = "Invalid URL"
            return
        }
        
        if !isPointingAtMac {
            // Optional: enforce pointing, but for ease of use we can just send it anyway or show a warning.
            // Let's enforce it.
            statusMessage = "Please point directly at your Mac!"
            // To make it easy and basic as the user requested, maybe we allow it to pass if they don't want strict compass.
            // We will send it anyway, but notify.
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
