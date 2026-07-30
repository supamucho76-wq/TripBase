import Foundation
import UserNotifications

enum NotificationScheduler {
    static let enabledKey = "departureRemindersEnabled"

    private static func reminderIdentifier(tripID: UUID, daysBefore: Int) -> String {
        "departure-reminder-\(tripID)-\(daysBefore)"
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Cancels any previously scheduled reminders for this trip and, if
    /// preparation is genuinely incomplete (unchecked packing items or
    /// unconfirmed documents) and reminders are enabled, schedules fresh
    /// 7-day/3-day/前日/当日 reminders ahead of the trip's first arrival date.
    /// Content reflects the state at scheduling time - call this again
    /// whenever packing/documents change so it stays reasonably fresh.
    static func scheduleDepartureReminders(
        tripID: UUID,
        tripName: String,
        firstArrivalDate: Date,
        packingRemainingCount: Int,
        documentsUnconfirmedCount: Int,
        now: Date = .now
    ) async {
        let center = UNUserNotificationCenter.current()
        await cancelReminders(tripID: tripID)

        guard UserDefaults.standard.bool(forKey: enabledKey) else { return }
        guard packingRemainingCount > 0 || documentsUnconfirmedCount > 0 else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let calendar = Calendar.current
        let intervals: [(daysBefore: Int, label: String)] = [
            (7, "7日前"), (3, "3日前"), (1, "前日"), (0, "当日")
        ]

        for interval in intervals {
            guard let fireDate = calendar.date(byAdding: .day, value: -interval.daysBefore, to: firstArrivalDate) else {
                continue
            }
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(tripName) 出発\(interval.label)"
            content.body = reminderBody(
                packingRemainingCount: packingRemainingCount,
                documentsUnconfirmedCount: documentsUnconfirmedCount
            )
            content.sound = .default

            var fireComponents = calendar.dateComponents([.year, .month, .day], from: fireDate)
            fireComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: reminderIdentifier(tripID: tripID, daysBefore: interval.daysBefore),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    static func cancelReminders(tripID: UUID) async {
        let identifiers = [7, 3, 1, 0].map { reminderIdentifier(tripID: tripID, daysBefore: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func reminderBody(packingRemainingCount: Int, documentsUnconfirmedCount: Int) -> String {
        var parts: [String] = []
        if packingRemainingCount > 0 {
            parts.append("持ち物が残り\(packingRemainingCount)件")
        }
        if documentsUnconfirmedCount > 0 {
            parts.append("未確認の書類が\(documentsUnconfirmedCount)件")
        }
        return parts.joined(separator: "、") + "あります。アプリで確認しましょう。"
    }
}
