import XCTest
@testable import JobHuntManager

/// マイページURL・ログインIDの保持
final class CompanyMypageTests: XCTestCase {
    /// 既存行は NULL で読まれるため、既定値は空文字でなければならない
    func testMypageFieldsDefaultToEmpty() {
        let company = Company(name: "カエデ製薬")

        XCTAssertEqual(company.mypageURLString, "")
        XCTAssertEqual(company.loginID, "")
    }

    func testMypageFieldsArePassedThroughInitializer() {
        let company = Company(
            name: "サクラ商事",
            mypageURLString: "mypage.sakura.example.com",
            loginID: "towa0829"
        )

        XCTAssertEqual(company.mypageURLString, "mypage.sakura.example.com")
        XCTAssertEqual(company.loginID, "towa0829")
    }

    /// 採用ページとマイページは別のフィールドで、互いに影響しない
    func testRecruitPageURLAndMypageURLAreIndependent() {
        let company = Company(
            name: "ヒナタ銀行",
            urlString: "recruit.hinata.example.com",
            mypageURLString: "mypage.hinata.example.com"
        )

        XCTAssertEqual(company.urlString, "recruit.hinata.example.com")
        XCTAssertEqual(company.mypageURLString, "mypage.hinata.example.com")
    }
}
