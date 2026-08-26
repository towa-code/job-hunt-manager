import XCTest
@testable import JobHuntManager

final class DateFormattingTests: XCTestCase {
    /// 端末の暦設定に左右されず西暦で出力されること（和暦設定だと "0008/06/15" になる退行を防ぐ）
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    func testFormattedDateUsesGregorianYear() {
        XCTAssertEqual(makeDate(year: 2026, month: 6, day: 15).formattedDate, "2026/06/15")
    }

    func testFormattedDateTimeUsesGregorianYear() {
        XCTAssertEqual(
            makeDate(year: 2026, month: 6, day: 15, hour: 14, minute: 30).formattedDateTime,
            "2026/06/15 14:30"
        )
    }

    /// インターン実施期間の短縮表記。和暦設定に引きずられないこと
    func testFormattedMonthDay() {
        XCTAssertEqual(makeDate(year: 2026, month: 8, day: 1).formattedMonthDay, "8/1")
        XCTAssertEqual(makeDate(year: 2026, month: 12, day: 25).formattedMonthDay, "12/25")
    }

    /// カレンダーのヘッダ表記。和暦設定でも西暦で出ること
    func testFormattedYearMonth() {
        XCTAssertEqual(makeDate(year: 2026, month: 8, day: 1).formattedYearMonth, "2026年8月")
        XCTAssertEqual(makeDate(year: 2027, month: 12, day: 31).formattedYearMonth, "2027年12月")
    }

    /// 日別リストは日付がセクション見出しに出るので、行では時刻だけを出す
    func testFormattedTime() {
        XCTAssertEqual(makeDate(year: 2026, month: 8, day: 12, hour: 9, minute: 5).formattedTime, "09:05")
        XCTAssertEqual(makeDate(year: 2026, month: 8, day: 12, hour: 14, minute: 30).formattedTime, "14:30")
    }

    func testRelativeDeadlineLabel() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        func offset(_ days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: today)! }

        XCTAssertEqual(offset(0).relativeDeadlineLabel, "今日")
        XCTAssertEqual(offset(1).relativeDeadlineLabel, "明日")
        XCTAssertEqual(offset(3).relativeDeadlineLabel, "あと3日")
        XCTAssertEqual(offset(-2).relativeDeadlineLabel, "2日超過")
    }
}
