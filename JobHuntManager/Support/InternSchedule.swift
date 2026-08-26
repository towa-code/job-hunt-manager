import Foundation

/// 月グリッドの1週に描く、インターン実施期間の帯1本分
///
/// 週をまたぐ期間は週ごとに分割されるので、1社が複数の `InternBar` を持つことがある。
struct InternBar: Identifiable {
    let company: Company
    /// `MonthGrid.days` を7日ずつに区切ったときの週番号（0..<6）
    let weekIndex: Int
    /// 週内での開始列（0..<7）
    let startColumn: Int
    /// 帯が占める列数（1...7）
    let columnSpan: Int
    /// 同じ週の中で縦に積む段。0 が最上段
    let lane: Int
    /// 週の左端で切れている（前の週から続いている）か
    let continuesFromPreviousWeek: Bool
    /// 週の右端で切れている（次の週へ続く）か
    let continuesToNextWeek: Bool

    var id: String { "\(company.id)-\(weekIndex)" }
}

/// インターンの実施期間を月グリッドの帯へ落とし込む
enum InternSchedule {
    private static let columnsPerWeek = 7

    /// 表示中の月グリッドに重なるインターンを、週ごとの帯へ変換する
    ///
    /// 月外のマスにも帯を描く。週行は連続しているので、月末をまたぐ帯を途中で切ると壊れて見えるため。
    static func bars(
        companies: [Company],
        grid: MonthGrid,
        calendar: Calendar = .current
    ) -> [InternBar] {
        let periods = companies.compactMap { period(of: $0, calendar: calendar) }
        guard !periods.isEmpty else { return [] }

        let days = grid.days
        var bars: [InternBar] = []

        for weekIndex in 0..<(days.count / columnsPerWeek) {
            let weekStart = days[weekIndex * columnsPerWeek]
            let weekEnd = days[weekIndex * columnsPerWeek + columnsPerWeek - 1]

            let segments = periods
                .compactMap { segment(of: $0, weekStart: weekStart, weekEnd: weekEnd, calendar: calendar) }
                .sorted(by: isOrderedBefore)

            // 段ごとに「最後に置いた帯の終了列」を持ち、空いている一番上の段へ詰める。
            // 開始列の昇順で見ているので、終了列が開始列より手前の段は空いていると判断できる。
            var lastColumnInLane: [Int] = []

            for segment in segments {
                let lane = lastColumnInLane.firstIndex { $0 < segment.startColumn } ?? lastColumnInLane.count
                if lane == lastColumnInLane.count {
                    lastColumnInLane.append(segment.endColumn)
                } else {
                    lastColumnInLane[lane] = segment.endColumn
                }

                bars.append(
                    InternBar(
                        company: segment.company,
                        weekIndex: weekIndex,
                        startColumn: segment.startColumn,
                        columnSpan: segment.endColumn - segment.startColumn + 1,
                        lane: lane,
                        continuesFromPreviousWeek: segment.continuesFromPreviousWeek,
                        continuesToNextWeek: segment.continuesToNextWeek
                    )
                )
            }
        }

        return bars
    }

    /// 指定日に実施中のインターンを、開始日の早い順に返す
    ///
    /// 期間の解釈は `bars(companies:grid:calendar:)` と共有する（帯とリストで食い違わないように）。
    static func internships(
        on day: Date,
        companies: [Company],
        calendar: Calendar = .current
    ) -> [Company] {
        let target = calendar.startOfDay(for: day)

        return companies
            .compactMap { period(of: $0, calendar: calendar) }
            .filter { $0.start <= target && target <= $0.end }
            .sorted { lhs, rhs in
                if lhs.start != rhs.start { return lhs.start < rhs.start }
                return lhs.company.name < rhs.company.name
            }
            .map(\.company)
    }

    /// 帯を描く対象の期間。0:00 に正規化済み
    private struct Period {
        let company: Company
        let start: Date
        let end: Date
    }

    /// 1週の中に収まるよう切り出した帯
    private struct Segment {
        let company: Company
        let startColumn: Int
        let endColumn: Int
        let continuesFromPreviousWeek: Bool
        let continuesToNextWeek: Bool
    }

    private static func period(of company: Company, calendar: Calendar) -> Period? {
        guard company.kind == .internship, let start = company.internStartDate else { return nil }

        let startDay = calendar.startOfDay(for: start)
        // 終了日が未設定なら1日開催（`internPeriodLabel` と同じ解釈）
        let endDay = calendar.startOfDay(for: company.internEndDate ?? start)

        return Period(company: company, start: startDay, end: max(startDay, endDay))
    }

    private static func segment(
        of period: Period,
        weekStart: Date,
        weekEnd: Date,
        calendar: Calendar
    ) -> Segment? {
        let clampedStart = max(period.start, weekStart)
        let clampedEnd = min(period.end, weekEnd)
        guard clampedStart <= clampedEnd else { return nil }

        let startColumn = calendar.dateComponents([.day], from: weekStart, to: clampedStart).day ?? 0
        let endColumn = calendar.dateComponents([.day], from: weekStart, to: clampedEnd).day ?? 0

        return Segment(
            company: period.company,
            startColumn: startColumn,
            endColumn: endColumn,
            continuesFromPreviousWeek: period.start < weekStart,
            continuesToNextWeek: period.end > weekEnd
        )
    }

    /// 開始列の昇順。同じ列から始まるなら長い帯を上の段に置く
    private static func isOrderedBefore(_ lhs: Segment, _ rhs: Segment) -> Bool {
        if lhs.startColumn != rhs.startColumn { return lhs.startColumn < rhs.startColumn }
        if lhs.endColumn != rhs.endColumn { return lhs.endColumn > rhs.endColumn }
        return lhs.company.name < rhs.company.name
    }
}
