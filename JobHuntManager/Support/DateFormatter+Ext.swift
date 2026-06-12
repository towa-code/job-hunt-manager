import Foundation

extension Date {
    /// 例: "2026/06/15"
    var formattedDate: String {
        Self.dateFormatter.string(from: self)
    }

    /// 例: "2026/06/15 14:30"
    var formattedDateTime: String {
        Self.dateTimeFormatter.string(from: self)
    }

    /// 例: "06/15 (月) 14:30"
    var formattedShortDateTime: String {
        Self.shortDateTimeFormatter.string(from: self)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()

    private static let shortDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd (E) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 今日から締切日までの残り日数（過去ならマイナス）
    var daysFromToday: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// 「今日」「あと3日」「2日超過」のような相対表示
    var relativeDeadlineLabel: String {
        let days = daysFromToday
        switch days {
        case 0: return "今日"
        case 1: return "明日"
        case 2...: return "あと\(days)日"
        default: return "\(-days)日超過"
        }
    }
}
