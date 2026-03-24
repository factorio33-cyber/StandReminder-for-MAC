import AppKit
import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class ReminderStore: NSObject, ObservableObject {
    @Published private(set) var settings: ReminderSettings
    @Published private(set) var phase: ReminderPhase = .working
    @Published private(set) var phaseStartedAt: Date
    @Published private(set) var now: Date
    @Published private(set) var transitionPrompt: TransitionPrompt?
    @Published private(set) var notificationsAuthorized = false
    @Published private(set) var notificationStatusText = "Checking notification permissions..."
    @Published private(set) var lastEventDescription = "Timer started."

    private let defaults = UserDefaults.standard
    private let settingsKey = "stand_up_reminder_settings"
    private let promptPresenter = TransitionPromptPresenter()
    private let reminderSound = ReminderStore.makeReminderSound()
    private var timer: Timer?
    private var observers: [ObserverToken] = []
    private var lastResetAt = Date.distantPast

    override init() {
        let loadedSettings = Self.loadSettings().clamped()
        let startDate = Date()

        settings = loadedSettings
        phaseStartedAt = startDate
        now = startDate

        super.init()

        configureObservers()
        startTimer()
        requestNotificationPermissionIfNeeded()
    }

    var currentDuration: TimeInterval {
        switch phase {
        case .working:
            return TimeInterval(settings.workingMinutes * 60)
        case .standing:
            return TimeInterval(settings.standingMinutes * 60)
        }
    }

    var phaseProgress: Double {
        guard currentDuration > 0 else {
            return 0
        }

        return min(max(now.timeIntervalSince(phaseStartedAt) / currentDuration, 0), 1)
    }

    var remainingSeconds: Int {
        let remaining = Int(ceil(currentDuration - now.timeIntervalSince(phaseStartedAt)))
        return max(remaining, 0)
    }

    var countdownText: String {
        Self.countdownText(for: remainingSeconds)
    }

    var compactCountdownText: String {
        Self.compactCountdownText(for: remainingSeconds)
    }

    var menuBarTitle: String {
        if let transitionPrompt {
            return transitionPrompt.menuBarTitle
        }

        switch phase {
        case .working:
            return compactCountdownText
        case .standing:
            return "Up \(compactCountdownText)"
        }
    }

    var headlineText: String {
        if let transitionPrompt {
            return transitionPrompt.statusText
        }

        switch phase {
        case .working:
            return "Next stand-up break in \(countdownText)"
        case .standing:
            return "Break ends in \(countdownText)"
        }
    }

    func binding<Value>(
        get: @escaping (ReminderSettings) -> Value,
        set: @escaping (inout ReminderSettings, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(self.settings) },
            set: { newValue in
                var updated = self.settings
                set(&updated, newValue)
                self.applySettings(updated)
            }
        )
    }

    func requestNotificationPermissionIfNeeded() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationsAuthorized = true
                notificationStatusText = "Notifications are enabled."
            case .denied:
                notificationsAuthorized = false
                notificationStatusText = "Notifications are blocked for this app."
            case .notDetermined:
                notificationStatusText = "Requesting notification access..."

                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound])
                    notificationsAuthorized = granted
                    notificationStatusText = granted
                        ? "Notifications are enabled."
                        : "Notifications are blocked for this app."
                } catch {
                    notificationsAuthorized = false
                    notificationStatusText = "Notification request failed: \(error.localizedDescription)"
                }
            @unknown default:
                notificationsAuthorized = false
                notificationStatusText = "Notification status is unavailable."
            }
        }
    }

    func resetCycle(reason: String) {
        resetToWorkingPhase(reason: reason, notification: nil)
    }

    func advancePhaseManually() {
        if transitionPrompt != nil {
            confirmPendingTransition()
        } else {
            advancePhaseImmediately()
        }
    }

    var primaryActionTitle: String {
        transitionPrompt?.confirmTitle ?? phase.actionTitle
    }

    func playTestReminderSound() {
        playReminderSound()
    }

    private func applySettings(_ updatedSettings: ReminderSettings) {
        let clampedSettings = updatedSettings.clamped()

        guard clampedSettings != settings else {
            return
        }

        settings = clampedSettings
        persistSettings()
        resetToWorkingPhase(
            reason: "Durations updated. Work timer restarted.",
            notification: nil
        )
    }

    private func configureObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let distributedCenter = DistributedNotificationCenter.default()

        let sessionObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetForSystemEvent(reason: "Session became inactive.")
            }
        }
        observers.append(ObserverToken(observer: sessionObserver) {
            workspaceCenter.removeObserver(sessionObserver)
        })

        let sleepObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetForSystemEvent(reason: "Display went to sleep.")
            }
        }
        observers.append(ObserverToken(observer: sleepObserver) {
            workspaceCenter.removeObserver(sleepObserver)
        })

        let lockObserver = distributedCenter.addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetForSystemEvent(reason: "Screen locked.")
            }
        }
        observers.append(ObserverToken(observer: lockObserver) {
            distributedCenter.removeObserver(lockObserver)
        })

        let unlockObserver = distributedCenter.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetForSystemEvent(reason: "Unlocked. Work timer restarted.")
            }
        }
        observers.append(ObserverToken(observer: unlockObserver) {
            distributedCenter.removeObserver(unlockObserver)
        })
    }

    private func resetForSystemEvent(reason: String) {
        let eventDate = Date()
        guard eventDate.timeIntervalSince(lastResetAt) > 2 else {
            return
        }

        lastResetAt = eventDate
        resetToWorkingPhase(reason: reason, notification: nil)
    }

    private func resetToWorkingPhase(reason: String, notification: (title: String, body: String)?) {
        transitionPrompt = nil
        promptPresenter.dismiss()
        phase = .working
        phaseStartedAt = Date()
        now = phaseStartedAt
        lastEventDescription = reason

        if let notification {
            _ = sendNotification(title: notification.title, body: notification.body)
        }
    }

    private func startTimer() {
        timer?.invalidate()

        let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        timer = ticker
        RunLoop.main.add(ticker, forMode: .common)
    }

    private func tick() {
        guard transitionPrompt == nil else {
            return
        }

        now = Date()

        guard now.timeIntervalSince(phaseStartedAt) >= currentDuration else {
            return
        }

        promptForPhaseTransition(shouldNotify: true)
    }

    private func advancePhaseImmediately() {
        let nextDate = Date()
        let nextPhase = phase.nextPhase

        transitionPrompt = nil
        promptPresenter.dismiss()
        phase = nextPhase
        phaseStartedAt = nextDate
        now = nextDate
        lastEventDescription = nextPhase == .standing
            ? "Stand-up break started."
            : "Back to work."
    }

    private func confirmPendingTransition() {
        guard transitionPrompt != nil else {
            return
        }

        advancePhaseImmediately()
    }

    private func promptForPhaseTransition(shouldNotify: Bool) {
        let prompt = makeTransitionPrompt()

        transitionPrompt = prompt
        lastEventDescription = prompt.statusText

        if shouldNotify {
            _ = sendNotification(title: prompt.title, body: prompt.message)
        }

        playReminderSound()

        promptPresenter.present(prompt: prompt) { [weak self] in
            Task { @MainActor in
                self?.confirmPendingTransition()
            }
        }
    }

    private func makeTransitionPrompt() -> TransitionPrompt {
        switch phase {
        case .working:
            return TransitionPrompt(
                completedPhase: .working,
                nextPhase: .standing,
                title: "Work session complete",
                message: "Your \(settings.workingMinutes)-minute work timer finished. Click below to start your \(settings.standingMinutes)-minute stand-up break.",
                confirmTitle: "Start Stand-Up Break",
                menuBarTitle: "Stand?",
                statusText: "Waiting for confirmation to start your stand-up break."
            )
        case .standing:
            return TransitionPrompt(
                completedPhase: .standing,
                nextPhase: .working,
                title: "Break finished",
                message: "Your \(settings.standingMinutes)-minute stand-up break ended. Click below to start your next \(settings.workingMinutes)-minute work session.",
                confirmTitle: "Start Work Session",
                menuBarTitle: "Work?",
                statusText: "Waiting for confirmation to start your next work session."
            )
        }
    }

    private func sendNotification(title: String, body: String) -> Bool {
        guard settings.notificationsEnabled else {
            return false
        }

        if !notificationsAuthorized {
            requestNotificationPermissionIfNeeded()
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        return true
    }

    private func playReminderSound() {
        guard settings.reminderSoundEnabled else {
            return
        }

        if let reminderSound {
            reminderSound.stop()
            reminderSound.play()
        } else {
            NSSound.beep()
        }
    }

    private static func makeReminderSound() -> NSSound? {
        let soundPaths = [
            "/System/Library/Sounds/Glass.aiff",
            "/System/Library/Sounds/Funk.aiff",
        ]

        for path in soundPaths where FileManager.default.fileExists(atPath: path) {
            if let sound = NSSound(contentsOfFile: path, byReference: true) {
                sound.volume = 1.0
                return sound
            }
        }

        if let sound = NSSound(named: NSSound.Name("Glass")) {
            sound.volume = 1.0
            sound.play()
            sound.stop()
            return sound
        }

        return nil
    }

    private func persistSettings() {
        guard let encoded = try? JSONEncoder().encode(settings) else {
            return
        }

        defaults.set(encoded, forKey: settingsKey)
    }

    private static func loadSettings() -> ReminderSettings {
        guard
            let data = UserDefaults.standard.data(forKey: "stand_up_reminder_settings"),
            let decoded = try? JSONDecoder().decode(ReminderSettings.self, from: data)
        else {
            return ReminderSettings()
        }

        return decoded
    }

    private static func countdownText(for totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static func compactCountdownText(for totalSeconds: Int) -> String {
        if totalSeconds >= 3600 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours)h\(minutes)m"
        }

        if totalSeconds >= 60 {
            return "\(totalSeconds / 60)m"
        }

        return "\(totalSeconds)s"
    }
}

private struct ObserverToken {
    let observer: NSObjectProtocol
    let remove: () -> Void
}
