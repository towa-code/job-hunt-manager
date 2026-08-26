import XCTest
@testable import JobHuntManager

/// `rawValue` は永続化値なので変えず、表示だけを `label` で吸収する
final class SelectionStatusTests: XCTestCase {
    func testWrittenTestIsDisplayedAsTest() {
        XCTAssertEqual(SelectionStatus.writtenTest.label, "テスト")
    }

    func testInterviewingIsDisplayedWithoutSuffix() {
        XCTAssertEqual(SelectionStatus.interviewing.label, "面接")
    }

    /// 保存済みデータが読めなくなるので rawValue は変えてはいけない
    func testRawValuesAreUnchanged() {
        XCTAssertEqual(SelectionStatus.writtenTest.rawValue, "筆記")
        XCTAssertEqual(SelectionStatus.interviewing.rawValue, "面接中")
    }

    func testOtherStatusesFallBackToRawValue() {
        XCTAssertEqual(SelectionStatus.offer.label, SelectionStatus.offer.rawValue)
        XCTAssertEqual(SelectionStatus.applied.label, SelectionStatus.applied.rawValue)
    }
}
