import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct StandUpReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ReminderStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
                .onAppear {
                    store.requestNotificationPermissionIfNeeded()
                }
        } label: {
            Label(store.menuBarTitle, systemImage: store.phase.menuBarSymbolName)
        }
        .menuBarExtraStyle(.window)
    }
}
