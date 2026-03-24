import AppKit
import SwiftUI

@MainActor
final class TransitionPromptPresenter {
    private var window: NSWindow?
    private var hostingController: NSHostingController<TransitionPromptView>?

    func present(prompt: TransitionPrompt, onConfirm: @escaping () -> Void) {
        let rootView = TransitionPromptView(prompt: prompt, onConfirm: onConfirm)

        if let hostingController {
            hostingController.rootView = rootView
        } else {
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = prompt.title
            window.styleMask = [.titled, .fullSizeContentView]
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.setContentSize(NSSize(width: 360, height: 230))

            self.hostingController = hostingController
            self.window = window
        }

        window?.title = prompt.title
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        window?.orderOut(nil)
    }
}

private struct TransitionPromptView: View {
    let prompt: TransitionPrompt
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: prompt.nextPhase == .standing ? "figure.walk.circle.fill" : "desktopcomputer.and.arrow.down")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)

            Text(prompt.title)
                .font(.title3.weight(.semibold))

            Text(prompt.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("The timer is paused until you confirm.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(prompt.confirmTitle) {
                onConfirm()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 360, height: 230)
    }
}
