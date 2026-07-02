//
//  SwipeApp.swift
//  Swipe
//
//  Created by Meidad Troper on 7/1/26.
//

import SwiftUI
import SwiftData

@main
struct SwipeApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Swipe", systemImage: "arrow.triangle.2.circlepath") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        #else
        WindowGroup {
            ContentView()
                .onAppear {
                    _ = MultipeerManager.shared // Initialize the manager
                }
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = MultipeerManager.shared // Initialize
        
        MultipeerManager.shared.onURLReceived = { url in
            OverlayManager.shared.showOverlay(for: url)
            NSWorkspace.shared.open(url)
        }
    }
}
#endif
