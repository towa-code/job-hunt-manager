import XCTest
import SwiftData
@testable import JobHuntManager

@MainActor
final class DayMarkersTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        // container は保持し続ける必要がある（解放すると mainContext が無効になる）
        container = try ModelContainer(
            for: Company.self, JobEvent.self, Submission.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() {
        container = nil
    }

    private var context: ModelContext { container.mainContext }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func markers(events: [JobEvent] = [], submissions: [Submission] = []) -> [Date: DayMarkers] {
        DayMarkers.markers(events: events, submissions: submissions, calendar: calendar)
    }

    func testEmptyInputProducesNoMarkers() {
        XCTAssertTrue(markers().isEmpty)
    }

    func testEventMarksItsDay() {
        let event = JobEvent(title: "一次面接", date: date(2026, 8, 12, hour: 14))
        context.insert(event)

        let result = markers(events: [event])

        XCTAssertEqual(result[date(2026, 8, 12)], DayMarkers(hasEvent: true, hasOpenSubmission: false))
    }

    /// 夜遅い予定でも当日のマスに付くこと（0:00 起点でキーを作る）
    func testLateNightEventIsKeyedToStartOfDay() {
        let event = JobEvent(title: "OB訪問", date: date(2026, 8, 12, hour: 23))
        context.insert(event)

        let result = markers(events: [event])

        XCTAssertNotNil(result[date(2026, 8, 12)])
        XCTAssertNil(result[date(2026, 8, 13)])
    }

    func testUnsubmittedSubmissionMarksItsDeadline() {
        let submission = Submission(title: "本選考ES", deadline: date(2026, 8, 20), status: .inProgress)
        context.insert(submission)

        let result = markers(submissions: [submission])

        XCTAssertEqual(result[date(2026, 8, 20)], DayMarkers(hasEvent: false, hasOpenSubmission: true))
    }

    /// 提出済みはカレンダー上のドットを出さない（締切タブの「未提出のみ」と揃える）
    func testSubmittedSubmissionProducesNoMarker() {
        let submission = Submission(title: "提出済ES", deadline: date(2026, 8, 20), status: .submitted)
        context.insert(submission)

        XCTAssertTrue(markers(submissions: [submission]).isEmpty)
    }

    func testDayWithBothEventAndDeadlineGetsBothMarkers() {
        let event = JobEvent(title: "説明会", date: date(2026, 8, 20, hour: 10))
        let submission = Submission(title: "本選考ES", deadline: date(2026, 8, 20, hour: 18), status: .notStarted)
        context.insert(event)
        context.insert(submission)

        let result = markers(events: [event], submissions: [submission])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[date(2026, 8, 20)], DayMarkers(hasEvent: true, hasOpenSubmission: true))
    }

    /// 同じ日に複数件あってもマーカーは 1 日 1 つに畳まれる
    func testMultipleEventsOnSameDayCollapseToOneMarker() {
        let morning = JobEvent(title: "説明会", date: date(2026, 8, 20, hour: 10))
        let evening = JobEvent(title: "一次面接", date: date(2026, 8, 20, hour: 18))
        context.insert(morning)
        context.insert(evening)

        let result = markers(events: [morning, evening])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[date(2026, 8, 20)], DayMarkers(hasEvent: true, hasOpenSubmission: false))
    }
}
