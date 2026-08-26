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

    /// 例: "8/1"
    var formattedMonthDay: String {
        Self.monthDayFormatter.string(from: self)
    }

    /// 例: "2026年8月"
    var formattedYearMonth: String {
        Self.yearMonthFormatter.string(from: self)
    }

    /// 例: "14:30"
    var formattedTime: String {
        Self.timeFormatter.string(from: self)
    }

    /// 例: "06/15 (月) 14:30"
    var formattedShortDateTime: String {
        Self.shortDateTimeFormatter.string(from: self)
    }

    /// 例: "平成15年4月1日"
    ///
    /// ES の生年月日欄が和暦指定のことがあるため、ここだけは意図的に和暦カレンダーを使う
    /// （他の固定フォーマットは端末の暦設定に引きずられないよう `en_US_POSIX` で西暦に固定している）
    var formattedJapaneseEra: String {
        Self.japaneseEraFormatter.string(from: self)
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 固定フォーマットには POSIX ロケールを指定する（端末が和暦設定でも西暦で出力するため）
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 固定フォーマットには POSIX ロケールを指定する（端末が和暦設定でも西暦で出力するため）
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()

    private static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let shortDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd (E) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    private static let japaneseEraFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // locale を代入すると calendar がその locale の暦で上書きされるので、locale → calendar の順で設定する
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateFormat = "Gy年M月d日"
        return formatter
    }()

    /// この日を誕生日とみなしたときの、`date` 時点の満年齢
    ///
    /// 基準日を注入できる形にしてあるのは、内部で `Date()` を直接読むとテストが書けず、
    /// アプリを開いたまま日付をまたいだときに表示が更新されないため。
    /// 日付の比較は他と同じく `startOfDay` 起点で行う。
    func age(asOf date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: self)
        let to = calendar.startOfDay(for: date)
        return calendar.dateComponents([.year], from: from, to: to).year ?? 0
    }

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
