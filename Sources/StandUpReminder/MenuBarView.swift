import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: ReminderStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(store.phase.title)
                .font(.title3.weight(.semibold))

            Text(store.headlineText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: store.phaseProgress)
                .progressViewStyle(.linear)

            Divider()

            Stepper(
                value: store.binding(
                    get: { $0.workingMinutes },
                    set: { $0.workingMinutes = $1 }
                ),
                in: 5...240,
                step: 5
            ) {
                row(title: "Work time", value: "\(store.settings.workingMinutes) min")
            }

            Stepper(
                value: store.binding(
                    get: { $0.standingMinutes },
                    set: { $0.standingMinutes = $1 }
                ),
                in: 1...60,
                step: 1
            ) {
                row(title: "Stand-up time", value: "\(store.settings.standingMinutes) min")
            }

            Toggle(
                "Desktop notifications",
                isOn: store.binding(
                    get: { $0.notificationsEnabled },
                    set: { $0.notificationsEnabled = $1 }
                )
            )

            Toggle(
                "Reminder sound",
                isOn: store.binding(
                    get: { $0.reminderSoundEnabled },
                    set: { $0.reminderSoundEnabled = $1 }
                )
            )

            Button("Play Test Sound") {
                store.playTestReminderSound()
            }

            Text(store.notificationStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !store.notificationsAuthorized {
                Button("Check Notification Permission") {
                    store.requestNotificationPermissionIfNeeded()
                }
            }

            Text(store.lastEventDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Reset Timer") {
                    store.resetCycle(reason: "Timer reset manually.")
                }

                Button(store.primaryActionTitle) {
                    store.advancePhaseManually()
                }
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    @ViewBuilder
    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
