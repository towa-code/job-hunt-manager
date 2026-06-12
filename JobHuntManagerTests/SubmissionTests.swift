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

extension SubmissionUrgency: Equatable {
    public static func == (lhs: SubmissionUrgency, rhs: SubmissionUrgency) -> Bool {
        switch (lhs, rhs) {
        case (.done, .done), (.overdue, .overdue), (.soon, .soon), (.normal, .normal):
            return true
        default:
            return false
        }
    }
}
