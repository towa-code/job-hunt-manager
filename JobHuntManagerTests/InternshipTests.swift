import XCTest
@testable import JobHuntManager

/// インターン選考対応（選考区分・実施期間・ホームのタイムライン統合）
final class InternshipTests: XCTestCase {
    private let calendar = Calendar.current

    /// 判定日は固定して注入する（`Date()` 直参照だと日付をまたいだ瞬間に落ちる）
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 26, hour: 10))!
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
    }

    private func internship(
        _ name: String,
        start: Date?,
        end: Date? = nil
    ) -> Company {
        let company = Company(name: name)
        company.kind = .internship
        company.internStartDate = start
        company.internEndDate = end
        return company
    }

    private func names(_ items: [UpcomingItem]) -> [String] {
        items.map { item in
            switch item.content {
            case .event(let event): return event.title
            case .internship(let company): return company.name
            }
        }
    }

    // MARK: - 選考区分

    func testKindDefaultsToFullTimeWhenUnset() {
        // 移行済みの既存行は kindRaw が NULL で読まれる
        let company = Company(name: "カエデ製薬")

        XCTAssertEqual(company.kind, .fullTime)
    }

    func testKindIsPersistedThroughRawStorage() {
        let company = Company(name: "カエデ製薬")

        company.kind = .internship

        XCTAssertEqual(company.kindRaw, .internship)
    }

    // MARK: - ステータスの表示ラベル

    func testStatusLabelIsRewrittenForInternship() {
        XCTAssertEqual(SelectionStatus.applied.label(for: .internship), "応募")
        XCTAssertEqual(SelectionStatus.offer.label(for: .internship), "参加確定")
    }

    func testStatusLabelIsUnchangedForFullTime() {
        XCTAssertEqual(SelectionStatus.applied.label(for: .fullTime), SelectionStatus.applied.rawValue)
        XCTAssertEqual(SelectionStatus.offer.label(for: .fullTime), SelectionStatus.offer.rawValue)
    }

    func testStatusLabelIsSharedWhenNotRewritten() {
        XCTAssertEqual(
            SelectionStatus.declined.label(for: .internship),
            SelectionStatus.declined.label(for: .fullTime)
        )
    }

    // MARK: - タイムラインへのインターンの載り方

    func testUpcomingInternshipIsListedOnItsStartDate() {
        let company = internship("アオバテック", start: day(3), end: day(7))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertEqual(names(items), ["アオバテック"])
        XCTAssertEqual(items.first?.date, day(3))
    }

    func testInProgressInternshipIsListedAsToday() {
        // 期間中のものは開始日が過去でも消さず、当日扱いで先頭に出す
        let company = internship("アオバテック", start: day(-2), end: day(2))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertEqual(names(items), ["アオバテック"])
        XCTAssertEqual(items.first?.date, calendar.startOfDay(for: now))
    }

    func testFinishedInternshipIsExcluded() {
        let company = internship("アオバテック", start: day(-9), end: day(-1))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertTrue(items.isEmpty)
    }

    func testInternshipEndingTodayIsStillListed() {
        let company = internship("アオバテック", start: day(-4), end: day(0))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertEqual(names(items), ["アオバテック"])
    }

    func testInternshipWithoutEndDateUsesStartDateAsEnd() {
        let oneDay = internship("アオバテック", start: day(0), end: nil)

        let items = UpcomingTimeline.items(events: [], companies: [oneDay], now: now)

        XCTAssertEqual(names(items), ["アオバテック"])
    }

    func testInternshipWithoutStartDateIsExcluded() {
        let company = internship("アオバテック", start: nil)

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertTrue(items.isEmpty)
    }

    func testFullTimeCompanyIsNeverListedAsInternship() {
        let company = Company(name: "サクラ商事")
        company.internStartDate = day(3)

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertTrue(items.isEmpty)
    }

    func testEventsAndInternshipsAreSortedTogetherByDate() {
        let interview = JobEvent(title: "二次面接", date: day(5))
        let briefing = JobEvent(title: "説明会", date: day(1))
        let camp = internship("アオバテック", start: day(3), end: day(7))

        let items = UpcomingTimeline.items(
            events: [interview, briefing],
            companies: [camp],
            now: now
        )

        XCTAssertEqual(names(items), ["説明会", "アオバテック", "二次面接"])
    }

    // MARK: - 実施中の判定

    func testInProgressInternshipIsMarkedInProgress() {
        let company = internship("アオバテック", start: day(-2), end: day(2))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertEqual(items.first?.isInProgress, true)
    }

    func testInternshipStartingTodayIsMarkedInProgress() {
        let company = internship("アオバテック", start: day(0), end: day(2))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertEqual(items.first?.isInProgress, true)
    }

    func testUpcomingInternshipIsNotMarkedInProgress() {
        let company = internship("アオバテック", start: day(3), end: day(7))

        let items = UpcomingTimeline.items(events: [], companies: [company], now: now)

        XCTAssertEqual(items.first?.isInProgress, false)
    }

    func testEventIsNeverMarkedInProgress() {
        let briefing = JobEvent(title: "説明会", date: day(1))

        let items = UpcomingTimeline.items(events: [briefing], companies: [], now: now)

        XCTAssertEqual(items.first?.isInProgress, false)
    }

    // MARK: - 実施期間の表示ラベル

    func testInternPeriodLabelShowsRange() {
        let company = internship("アオバテック", start: day(3), end: day(7))

        XCTAssertEqual(company.internPeriodLabel, "8/29〜9/2")
    }

    func testInternPeriodLabelShowsSingleDayWhenEndDateIsMissing() {
        let company = internship("アオバテック", start: day(3), end: nil)

        XCTAssertEqual(company.internPeriodLabel, "8/29")
    }

    func testInternPeriodLabelIsNilForFullTime() {
        let company = Company(name: "サクラ商事")
        company.internStartDate = day(3)

        XCTAssertNil(company.internPeriodLabel)
    }

    func testInternPeriodLabelIsNilWithoutStartDate() {
        let company = internship("アオバテック", start: nil)

        XCTAssertNil(company.internPeriodLabel)
    }

    // MARK: - 「今後7日」の件数

    func testWeekCountIncludesInternshipStartingWithinSevenDays() {
        let company = internship("アオバテック", start: day(6), end: day(10))

        let count = UpcomingTimeline.weekCount(events: [], companies: [company], now: now)

        XCTAssertEqual(count, 1)
    }

    func testWeekCountExcludesInternshipStartingOnTheEighthDay() {
        // 7日後ちょうどは範囲外（既存の予定の集計と同じ [今日0:00, +7日) の半開区間）
        let company = internship("アオバテック", start: day(7), end: day(10))

        let count = UpcomingTimeline.weekCount(events: [], companies: [company], now: now)

        XCTAssertEqual(count, 0)
    }

    func testWeekCountCountsEventsAndInternshipsTogether() {
        let briefing = JobEvent(title: "説明会", date: day(1))
        let company = internship("アオバテック", start: day(2), end: day(5))

        let count = UpcomingTimeline.weekCount(
            events: [briefing],
            companies: [company],
            now: now
        )

        XCTAssertEqual(count, 2)
    }
}
