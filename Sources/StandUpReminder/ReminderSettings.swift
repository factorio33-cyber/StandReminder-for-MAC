import Foundation

struct ReminderSettings: Codable, Equatable {
    var workingMinutes: Int = 55
    var standingMinutes: Int = 5
    var notificationsEnabled: Bool = true
    var reminderSoundEnabled: Bool = true

    init(
        workingMinutes: Int = 55,
        standingMinutes: Int = 5,
        notificationsEnabled: Bool = true,
        reminderSoundEnabled: Bool = true
    ) {
        self.workingMinutes = workingMinutes
        self.standingMinutes = standingMinutes
        self.notificationsEnabled = notificationsEnabled
        self.reminderSoundEnabled = reminderSoundEnabled
    }

    enum CodingKeys: String, CodingKey {
        case workingMinutes
        case standingMinutes
        case notificationsEnabled
        case reminderSoundEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.workingMinutes = try container.decodeIfPresent(Int.self, forKey: .workingMinutes) ?? 55
        self.standingMinutes = try container.decodeIfPresent(Int.self, forKey: .standingMinutes) ?? 5
        self.notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        self.reminderSoundEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderSoundEnabled) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workingMinutes, forKey: .workingMinutes)
        try container.encode(standingMinutes, forKey: .standingMinutes)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(reminderSoundEnabled, forKey: .reminderSoundEnabled)
    }

    func clamped() -> ReminderSettings {
        ReminderSettings(
            workingMinutes: min(max(workingMinutes, 5), 240),
            standingMinutes: min(max(standingMinutes, 1), 60),
            notificationsEnabled: notificationsEnabled,
            reminderSoundEnabled: reminderSoundEnabled
        )
    }
}

enum ReminderPhase {
    case working
    case standing

    var title: String {
        switch self {
        case .working:
            return "Working"
        case .standing:
            return "Stand Up"
        }
    }

    var menuBarSymbolName: String {
        switch self {
        case .working:
            return "desktopcomputer"
        case .standing:
            return "figure.walk"
        }
    }

    var actionTitle: String {
        switch self {
        case .working:
            return "Start Break"
        case .standing:
            return "Back to Work"
        }
    }

    var nextPhase: ReminderPhase {
        switch self {
        case .working:
            return .standing
        case .standing:
            return .working
        }
    }
}

struct TransitionPrompt: Equatable {
    let completedPhase: ReminderPhase
    let nextPhase: ReminderPhase
    let title: String
    let message: String
    let confirmTitle: String
    let menuBarTitle: String
    let statusText: String
}
