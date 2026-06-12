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
}
