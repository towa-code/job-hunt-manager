import XCTest
@testable import JobHuntManager

/// カレンダーの月グリッドに描くインターン実施期間の帯
final class InternScheduleTests: XCTestCase {
    /// 日曜始まりのグレゴリオ暦（日本の端末設定に相当）
    private func sundayFirstCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.timeZone = .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func internship(_ name: String, _ start: Date, _ end: Date? = nil) -> Company {
        let company = Company(name: name)
        company.kind = .internship
        company.internStartDate = start
        company.internEndDate = end
        return company
    }

    /// 2026年8月のグリッド。日曜始まりなので 7/26(日) 〜 9/5(土) の42マス
    private func augustGrid() -> MonthGrid {
        MonthGrid(containing: date(2026, 8, 15), calendar: sundayFirstCalendar())
    }

    private func bars(_ companies: [Company]) -> [InternBar] {
        InternSchedule.bars(
            companies: companies,
            grid: augustGrid(),
            calendar: sundayFirstCalendar()
        )
    }

    // MARK: - 期間の切り出し

    /// 週内で完結する期間は1本の帯になる。8/17(月)〜8/19(水) は第4週の列1〜3
    func testPeriodInsideSingleWeekProducesOneBar() {
        let result = bars([internship("カエデ製薬", date(2026, 8, 17), date(2026, 8, 19))])

        XCTAssertEqual(result.count, 1)
        let bar = result[0]
        XCTAssertEqual(bar.weekIndex, 3)
        XCTAssertEqual(bar.startColumn, 1)
        XCTAssertEqual(bar.columnSpan, 3)
        XCTAssertFalse(bar.continuesFromPreviousWeek)
        XCTAssertFalse(bar.continuesToNextWeek)
    }

    /// 週をまたぐ期間は週ごとに分割し、切れた側にフラグを立てる。8/16(日)〜8/23(日)
    func testPeriodAcrossWeeksSplitsIntoSegments() {
        let result = bars([internship("カエデ製薬", date(2026, 8, 16), date(2026, 8, 23))])

        XCTAssertEqual(result.count, 2)

        let first = result[0]
        XCTAssertEqual(first.weekIndex, 3)
        XCTAssertEqual(first.startColumn, 0)
        XCTAssertEqual(first.columnSpan, 7)
        XCTAssertFalse(first.continuesFromPreviousWeek)
        XCTAssertTrue(first.continuesToNextWeek)

        let second = result[1]
        XCTAssertEqual(second.weekIndex, 4)
        XCTAssertEqual(second.startColumn, 0)
        XCTAssertEqual(second.columnSpan, 1)
        XCTAssertTrue(second.continuesFromPreviousWeek)
        XCTAssertFalse(second.continuesToNextWeek)
    }

    /// 終了日が未設定なら1日開催として扱う（`internPeriodLabel` と同じ解釈）
    func testMissingEndDateIsTreatedAsSingleDay() {
        let result = bars([internship("カエデ製薬", date(2026, 8, 17))])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].columnSpan, 1)
        XCTAssertEqual(result[0].startColumn, 1)
    }

    /// 月外の日にも帯を描く。週行は連続しているので、月末をまたぐ帯を途中で切らない
    func testPeriodSpillingOutOfMonthIsStillDrawnInsideGrid() {
        // 8/31(月)〜9/2(水)。9月分もグリッド上の第6週に入っている
        let result = bars([internship("カエデ製薬", date(2026, 8, 31), date(2026, 9, 2))])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].weekIndex, 5)
        XCTAssertEqual(result[0].startColumn, 1)
        XCTAssertEqual(result[0].columnSpan, 3)
    }

    /// グリッドの端で打ち切る。7/20 開始はグリッド先頭(7/26)より前なので、続きとして描く
    func testPeriodStartingBeforeGridIsClippedAtGridStart() {
        let result = bars([internship("カエデ製薬", date(2026, 7, 20), date(2026, 7, 28))])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].weekIndex, 0)
        XCTAssertEqual(result[0].startColumn, 0)
        XCTAssertEqual(result[0].columnSpan, 3)
        XCTAssertTrue(result[0].continuesFromPreviousWeek)
    }

    // MARK: - 対象の絞り込み

    /// 本選考の企業と、開始日が未設定のインターンは帯を持たない
    func testFullTimeAndUndatedCompaniesProduceNoBars() {
        let fullTime = Company(name: "カエデ製薬")
        fullTime.internStartDate = date(2026, 8, 17)

        let undated = Company(name: "ツバキ商事")
        undated.kind = .internship

        XCTAssertTrue(bars([fullTime, undated]).isEmpty)
    }

    /// グリッドの範囲外の期間は描かない
    func testPeriodOutsideGridProducesNoBars() {
        let result = bars([internship("カエデ製薬", date(2026, 10, 5), date(2026, 10, 9))])

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - レーン割り当て

    /// 重なる期間は別の段に積む。段が重なることが「日程が被っている」の手がかりになる
    func testOverlappingPeriodsAreStackedIntoSeparateLanes() {
        // 渡す順番に依存しないことも同時に確かめる
        let result = bars([
            internship("ツバキ商事", date(2026, 8, 18), date(2026, 8, 20)),
            internship("カエデ製薬", date(2026, 8, 17), date(2026, 8, 19)),
            internship("スミレ電機", date(2026, 8, 19), date(2026, 8, 21))
        ])

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(lane(of: "カエデ製薬", in: result), 0)
        XCTAssertEqual(lane(of: "ツバキ商事", in: result), 1)
        XCTAssertEqual(lane(of: "スミレ電機", in: result), 2)
    }

    /// 重ならなければ同じ段を使い回す
    func testNonOverlappingPeriodsShareTheSameLane() {
        let result = bars([
            internship("カエデ製薬", date(2026, 8, 17), date(2026, 8, 18)),
            internship("ツバキ商事", date(2026, 8, 20), date(2026, 8, 21))
        ])

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(lane(of: "カエデ製薬", in: result), 0)
        XCTAssertEqual(lane(of: "ツバキ商事", in: result), 0)
    }

    /// 段は週ごとに詰め直す。前の週で塞いでいた帯が終われば、次の週では上に上がる
    func testLanesArePackedPerWeek() {
        let result = bars([
            // 第4週(8/16〜8/22)いっぱいで終わる
            internship("カエデ製薬", date(2026, 8, 16), date(2026, 8, 22)),
            // 第4週では2段目、第5週では他がいないので1段目に上がる
            internship("ツバキ商事", date(2026, 8, 18), date(2026, 8, 25))
        ])

        let tsubaki = result.filter { $0.company.name == "ツバキ商事" }
        XCTAssertEqual(tsubaki.count, 2)
        XCTAssertEqual(tsubaki[0].weekIndex, 3)
        XCTAssertEqual(tsubaki[0].lane, 1)
        XCTAssertEqual(tsubaki[1].weekIndex, 4)
        XCTAssertEqual(tsubaki[1].lane, 0)
    }

    private func lane(of name: String, in bars: [InternBar]) -> Int? {
        bars.first { $0.company.name == name }?.lane
    }

    // MARK: - 指定日に実施中のインターン

    private func internships(on day: Date, _ companies: [Company]) -> [String] {
        InternSchedule.internships(
            on: day,
            companies: companies,
            calendar: sundayFirstCalendar()
        ).map(\.name)
    }

    /// 初日・最終日を含む。開始日の早い順に並ぶ
    func testInternshipsOnDayIncludesBoundariesAndSortsByStart() {
        let companies = [
            internship("ツバキ商事", date(2026, 8, 20), date(2026, 8, 24)),
            internship("カエデ製薬", date(2026, 8, 18), date(2026, 8, 22))
        ]

        XCTAssertEqual(internships(on: date(2026, 8, 18), companies), ["カエデ製薬"])
        XCTAssertEqual(internships(on: date(2026, 8, 21), companies), ["カエデ製薬", "ツバキ商事"])
        XCTAssertEqual(internships(on: date(2026, 8, 24), companies), ["ツバキ商事"])
    }

    /// 期間外は返さない
    func testInternshipsOnDayExcludesDaysOutsidePeriod() {
        let companies = [internship("カエデ製薬", date(2026, 8, 18), date(2026, 8, 22))]

        XCTAssertTrue(internships(on: date(2026, 8, 17), companies).isEmpty)
        XCTAssertTrue(internships(on: date(2026, 8, 23), companies).isEmpty)
    }

    /// 時刻を持つ日付で引いても、その日の 0:00 起点で判定する
    func testInternshipsOnDayIgnoresTimeOfDay() {
        var calendar = sundayFirstCalendar()
        calendar.timeZone = .current
        let noon = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 22, hour: 23, minute: 30)
        )!
        let companies = [internship("カエデ製薬", date(2026, 8, 18), date(2026, 8, 22))]

        XCTAssertEqual(
            InternSchedule.internships(on: noon, companies: companies, calendar: calendar).map(\.name),
            ["カエデ製薬"]
        )
    }

    /// 終了日が未設定なら開始日1日だけ
    func testInternshipsOnDayTreatsMissingEndDateAsSingleDay() {
        let companies = [internship("カエデ製薬", date(2026, 8, 18))]

        XCTAssertEqual(internships(on: date(2026, 8, 18), companies), ["カエデ製薬"])
        XCTAssertTrue(internships(on: date(2026, 8, 19), companies).isEmpty)
    }

    /// 本選考の企業は期間を持っていても返さない
    func testInternshipsOnDayExcludesFullTimeCompanies() {
        let fullTime = Company(name: "カエデ製薬")
        fullTime.internStartDate = date(2026, 8, 18)
        fullTime.internEndDate = date(2026, 8, 22)

        XCTAssertTrue(internships(on: date(2026, 8, 20), [fullTime]).isEmpty)
    }
}
