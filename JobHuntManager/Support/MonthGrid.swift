import Foundation

/// ある月を 週×7日 のマスで表すグリッド（SwiftData に依存しない）
///
/// 週数は月によって 4〜6 で変わる。**表示月の日が1つも入らない週は作らない**
/// （2026年9月は最終週が10/4〜10/10 で丸ごと翌月になるため、5週で打ち切る）。
struct MonthGrid {
    /// 表示月の1日 0:00
    let firstOfMonth: Date
    /// 週数 × 7 要素。各要素は 0:00 に正規化済み
    let days: [Date]
    /// 曜日ヘッダ。firstWeekday の並び
    let weekdaySymbols: [String]

    private let calendar: Calendar

    init(containing date: Date, calendar: Calendar = .current) {
        self.calendar = calendar

        let startOfGivenDay = calendar.startOfDay(for: date)
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: startOfGivenDay)
        ) ?? startOfGivenDay
        firstOfMonth = monthStart

        // 月初から週開始曜日まで遡った日をグリッドの先頭にする
        let weekdayOfMonthStart = calendar.component(.weekday, from: monthStart)
        let leadingDays = (weekdayOfMonthStart - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart

        // 表示月の日を収めるのに必要な週数だけ作る
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 31
        let weekCount = (leadingDays + daysInMonth + 6) / 7

        days = (0..<(weekCount * 7)).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
            return calendar.startOfDay(for: day)
        }

        // 端末のロケールに関係なく日本語の曜日を出す（表示フォーマットを ja_JP で揃える方針に合わせる）
        var japaneseCalendar = calendar
        japaneseCalendar.locale = Locale(identifier: "ja_JP")
        let symbols = japaneseCalendar.shortWeekdaySymbols
        weekdaySymbols = (0..<symbols.count).map { offset in
            symbols[(calendar.firstWeekday - 1 + offset) % symbols.count]
        }
    }

    func isInDisplayedMonth(_ day: Date) -> Bool {
        calendar.isDate(day, equalTo: firstOfMonth, toGranularity: .month)
    }

    func adding(months: Int) -> MonthGrid {
        let shifted = calendar.date(byAdding: .month, value: months, to: firstOfMonth) ?? firstOfMonth
        return MonthGrid(containing: shifted, calendar: calendar)
    }
}

/// カレンダーの1マスに出すドットの有無
struct DayMarkers: Equatable {
    var hasEvent: Bool
    var hasOpenSubmission: Bool

    /// 予定と未提出の提出物を「日(0:00) → マーカー」の辞書に畳む
    ///
    /// 提出済みの提出物はドットを出さない（締切タブの「未提出のみ」と揃える）。
    static func markers(
        events: [JobEvent],
        submissions: [Submission],
        calendar: Calendar = .current
    ) -> [Date: DayMarkers] {
        let empty = DayMarkers(hasEvent: false, hasOpenSubmission: false)
        var markers: [Date: DayMarkers] = [:]

        for event in events {
            markers[calendar.startOfDay(for: event.date), default: empty].hasEvent = true
        }
        for submission in submissions where submission.status != .submitted {
            markers[calendar.startOfDay(for: submission.deadline), default: empty].hasOpenSubmission = true
        }

        return markers
    }
}
