import XCTest
@testable import JobHuntManager

final class MonthGridTests: XCTestCase {
    /// 日曜始まりのグレゴリオ暦（日本の端末設定に相当）
    private func sundayFirstCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.timeZone = .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// マス数は表示月を収めるのに必要な週数ぶんだけ。月によって 4〜6 週で変わる
    func testGridHasOnlyTheWeeksTheMonthNeeds() {
        let calendar = sundayFirstCalendar()

        // 2026/8/1 は土曜なので前に6日ぶら下がり、31日と合わせて6週
        XCTAssertEqual(MonthGrid(containing: date(2026, 8, 15), calendar: calendar).days.count, 42)
        // 2026/9/1 は火曜。前に2日＋30日で32日ぶんなので5週で収まる
        XCTAssertEqual(MonthGrid(containing: date(2026, 9, 15), calendar: calendar).days.count, 35)
        // 2026/2/1 は日曜で28日ちょうど。4週で収まる
        XCTAssertEqual(MonthGrid(containing: date(2026, 2, 15), calendar: calendar).days.count, 28)
    }

    /// 表示月の日が1つも入らない週は作らない（9月の最終行が10月だけになるのを防ぐ）
    func testGridNeverEndsWithAWeekOutsideTheMonth() {
        let calendar = sundayFirstCalendar()

        for month in 1...12 {
            let grid = MonthGrid(containing: date(2026, month, 15), calendar: calendar)
            let lastWeek = grid.days.suffix(7)

            XCTAssertTrue(
                lastWeek.contains { grid.isInDisplayedMonth($0) },
                "2026年\(month)月の最終週に表示月の日が1つもない"
            )
        }
    }

    /// 先頭マスは月初の直前（または当日）の週開始曜日。2026/8/1 は土曜なので日曜始まりでは 7/26
    func testGridStartsAtFirstWeekdayOnOrBeforeMonthStart() {
        let grid = MonthGrid(containing: date(2026, 8, 15), calendar: sundayFirstCalendar())

        XCTAssertEqual(grid.days.first, date(2026, 7, 26))
        XCTAssertEqual(grid.days.last, date(2026, 9, 5))
    }

    /// 週開始曜日はハードコードせず Calendar に従う。月曜始まりなら先頭は 7/27
    func testGridRespectsFirstWeekday() {
        var calendar = sundayFirstCalendar()
        calendar.firstWeekday = 2

        let grid = MonthGrid(containing: date(2026, 8, 15), calendar: calendar)

        XCTAssertEqual(grid.days.first, date(2026, 7, 27))
    }

    /// 月初が週開始曜日そのものの月で、前月を1週間まるごと余計に表示しないこと
    func testGridStartsAtMonthStartWhenMonthBeginsOnFirstWeekday() {
        // 2026/11/1 は日曜
        let grid = MonthGrid(containing: date(2026, 11, 15), calendar: sundayFirstCalendar())

        XCTAssertEqual(grid.days.first, date(2026, 11, 1))
    }

    /// マスの時刻は 0:00 に揃える（辞書のキーとして使うため）
    func testAllDaysAreStartOfDay() {
        let calendar = sundayFirstCalendar()
        let grid = MonthGrid(containing: date(2026, 8, 15, hour: 23), calendar: calendar)

        for day in grid.days {
            XCTAssertEqual(day, calendar.startOfDay(for: day))
        }
    }

    /// 何時に生成しても同じ月の同じグリッドになること
    func testGridIsIndependentOfTimeOfDay() {
        let calendar = sundayFirstCalendar()

        let morning = MonthGrid(containing: date(2026, 8, 1, hour: 0), calendar: calendar)
        let night = MonthGrid(containing: date(2026, 8, 31, hour: 23), calendar: calendar)

        XCTAssertEqual(morning.days, night.days)
    }

    func testIsInDisplayedMonth() {
        let grid = MonthGrid(containing: date(2026, 8, 15), calendar: sundayFirstCalendar())

        XCTAssertFalse(grid.isInDisplayedMonth(date(2026, 7, 31)))
        XCTAssertTrue(grid.isInDisplayedMonth(date(2026, 8, 1)))
        XCTAssertTrue(grid.isInDisplayedMonth(date(2026, 8, 31)))
        XCTAssertFalse(grid.isInDisplayedMonth(date(2026, 9, 1)))
    }

    func testFirstOfMonthIsNormalizedToMonthStart() {
        let grid = MonthGrid(containing: date(2026, 8, 15, hour: 23), calendar: sundayFirstCalendar())

        XCTAssertEqual(grid.firstOfMonth, date(2026, 8, 1))
    }

    func testAddingMonthsMovesForward() {
        let grid = MonthGrid(containing: date(2026, 8, 15), calendar: sundayFirstCalendar())

        XCTAssertEqual(grid.adding(months: 1).firstOfMonth, date(2026, 9, 1))
    }

    /// 年をまたぐ移動（12月 → 翌年1月、1月 → 前年12月）
    func testAddingMonthsCrossesYearBoundary() {
        let calendar = sundayFirstCalendar()
        let december = MonthGrid(containing: date(2026, 12, 15), calendar: calendar)

        XCTAssertEqual(december.adding(months: 1).firstOfMonth, date(2027, 1, 1))
        XCTAssertEqual(december.adding(months: -11).firstOfMonth, date(2026, 1, 1))
    }

    /// 月末日の少ない月へ移動しても日付が溢れないこと（8/31 → 2月）
    func testAddingMonthsFromMonthEndDoesNotOverflow() {
        let grid = MonthGrid(containing: date(2026, 8, 31), calendar: sundayFirstCalendar())

        XCTAssertEqual(grid.adding(months: -6).firstOfMonth, date(2026, 2, 1))
    }

    /// 曜日ヘッダは firstWeekday の並びで、端末ロケールによらず日本語
    func testWeekdaySymbolsAreJapaneseAndRotatedByFirstWeekday() {
        var calendar = sundayFirstCalendar()
        calendar.locale = Locale(identifier: "en_US")

        XCTAssertEqual(
            MonthGrid(containing: date(2026, 8, 15), calendar: calendar).weekdaySymbols,
            ["日", "月", "火", "水", "木", "金", "土"]
        )

        calendar.firstWeekday = 2
        XCTAssertEqual(
            MonthGrid(containing: date(2026, 8, 15), calendar: calendar).weekdaySymbols,
            ["月", "火", "水", "木", "金", "土", "日"]
        )
    }
}
