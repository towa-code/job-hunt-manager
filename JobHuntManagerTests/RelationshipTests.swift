import XCTest
import SwiftData
@testable import JobHuntManager

@MainActor
final class RelationshipTests: XCTestCase {
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

    /// イニシャライザで company を渡すだけで逆関係が張られること（明示的な append を足すと重複する）
    func testInsertingEventLinksToCompanyExactlyOnce() throws {
        let company = Company(name: "テスト商事")
        context.insert(company)

        context.insert(JobEvent(title: "一次面接", company: company))

        XCTAssertEqual(company.events.count, 1)
        XCTAssertEqual(company.events.first?.title, "一次面接")
    }

    func testInsertingSubmissionLinksToCompanyExactlyOnce() throws {
        let company = Company(name: "テスト商事")
        context.insert(company)

        context.insert(Submission(title: "本選考ES", company: company))

        XCTAssertEqual(company.submissions.count, 1)
        XCTAssertEqual(company.submissions.first?.title, "本選考ES")
    }

    /// 企業を削除したら紐づく予定・提出物も消えること（cascade）
    func testDeletingCompanyCascadesToChildren() throws {
        let company = Company(name: "テスト商事")
        context.insert(company)
        context.insert(JobEvent(title: "一次面接", company: company))
        context.insert(Submission(title: "本選考ES", company: company))
        try context.save()

        context.delete(company)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<JobEvent>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Submission>()), 0)
    }
}
