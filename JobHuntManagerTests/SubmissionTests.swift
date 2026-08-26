import XCTest
import Foundation
@testable import JobHuntManager

final class SubmissionTests: XCTestCase {
    private let calendar = Calendar.current

    func testUrgencyIsDoneWhenSubmitted() {
        let submission = Submission(
            title: "ES",
            deadline: Date().addingTimeInterval(-86400),
            status: .submitted
        )
        XCTAssertEqual(submission.urgency, .done)
    }

    func testUrgencyIsOverdueWhenDeadlinePassed() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let submission = Submission(
            title: "ES",
            deadline: yesterday,
            status: .notStarted
        )
        XCTAssertEqual(submission.urgency, .overdue)
    }

    func testUrgencyIsSoonWithinThreeDays() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let submission = Submission(
            title: "ES",
            deadline: tomorrow,
            status: .inProgress
        )
        XCTAssertEqual(submission.urgency, .soon)
    }

    /// 3日以内が soon、ちょうど3日後は normal という境界
    func testUrgencyBoundaryAtThreeDays() {
        let twoDaysLater = calendar.date(byAdding: .day, value: 2, to: Date())!
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: Date())!
        XCTAssertEqual(Submission(title: "ES", deadline: twoDaysLater).urgency, .soon)
        XCTAssertEqual(Submission(title: "ES", deadline: threeDaysLater).urgency, .normal)
    }

    func testUrgencyIsNormalWhenFarInFuture() {
        let nextWeek = calendar.date(byAdding: .day, value: 10, to: Date())!
        let submission = Submission(
            title: "ES",
            deadline: nextWeek,
            status: .notStarted
        )
        XCTAssertEqual(submission.urgency, .normal)
    }
}
