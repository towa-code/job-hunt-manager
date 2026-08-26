import XCTest
import SwiftData
@testable import JobHuntManager

/// プロフィール（ES・応募フォームへの転記元）
final class ProfileTests: XCTestCase {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: - 年齢

    /// 満年齢は誕生日の当日に上がる。基準日は注入するので端末の日付に依存しない
    func testAgeIncrementsOnBirthday() {
        let birthday = date(2003, 4, 1)

        XCTAssertEqual(birthday.age(asOf: date(2026, 3, 31)), 22)
        XCTAssertEqual(birthday.age(asOf: date(2026, 4, 1)), 23)
        XCTAssertEqual(birthday.age(asOf: date(2026, 4, 2)), 23)
    }

    /// 時刻ではなく 0:00 起点で判定すること（誕生日当日の朝に 1 歳若く出ると困る）
    func testAgeUsesStartOfDay() {
        let birthday = calendar.date(from: DateComponents(year: 2003, month: 4, day: 1, hour: 23))!
        let morningOfBirthday = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 1))!

        XCTAssertEqual(birthday.age(asOf: morningOfBirthday), 23)
    }

    /// 2/29 生まれは平年に 2/29 が無いので 2/28 の時点で歳が上がる
    /// （年齢計算ニ関スル法律の「誕生日の前日終了時に加齢」と同じ結果になる）
    func testAgeForLeapDayBirthday() {
        let birthday = date(2004, 2, 29)

        XCTAssertEqual(birthday.age(asOf: date(2027, 2, 27)), 22)
        XCTAssertEqual(birthday.age(asOf: date(2027, 2, 28)), 23)
        XCTAssertEqual(birthday.age(asOf: date(2027, 3, 1)), 23)
        XCTAssertEqual(birthday.age(asOf: date(2028, 2, 29)), 24)
    }

    // MARK: - 和暦

    /// ES の生年月日欄が和暦指定のことがあるため、和暦表記を別に持つ
    func testFormattedJapaneseEra() {
        XCTAssertEqual(date(2003, 4, 1).formattedJapaneseEra, "平成15年4月1日")
        XCTAssertEqual(date(2026, 12, 25).formattedJapaneseEra, "令和8年12月25日")
    }

    /// 元号の境界。昭和 → 平成 は 1989/01/08、平成 → 令和 は 2019/05/01
    /// 各元号の1年目は Foundation が "元年" と表記する
    func testFormattedJapaneseEraAtEraBoundaries() {
        XCTAssertEqual(date(1989, 1, 7).formattedJapaneseEra, "昭和64年1月7日")
        XCTAssertEqual(date(1989, 1, 8).formattedJapaneseEra, "平成元年1月8日")
        XCTAssertEqual(date(2019, 4, 30).formattedJapaneseEra, "平成31年4月30日")
        XCTAssertEqual(date(2019, 5, 1).formattedJapaneseEra, "令和元年5月1日")
    }

    /// 和暦を足したせいで既存の西暦フォーマットが引きずられないこと
    func testGregorianFormattingIsUnaffected() {
        XCTAssertEqual(date(2003, 4, 1).formattedDate, "2003/04/01")
        XCTAssertEqual(date(2026, 12, 25).formattedYearMonth, "2026年12月")
    }

    // MARK: - 氏名

    /// ES の氏名欄が1つしかないときのために、結合形もコピーできるようにする
    func testFullNameJoinsWithSpace() {
        let profile = Profile()
        profile.familyName = "鈴木"
        profile.givenName = "太郎"
        profile.familyNameKana = "スズキ"
        profile.givenNameKana = "タロウ"

        XCTAssertEqual(profile.fullName, "鈴木 太郎")
        XCTAssertEqual(profile.fullNameKana, "スズキ タロウ")
    }

    /// 片方だけ入力途中でも、余分な空白が残らないこと
    func testFullNameWithMissingHalf() {
        let profile = Profile()
        profile.familyName = "鈴木"

        XCTAssertEqual(profile.fullName, "鈴木")
        XCTAssertEqual(profile.fullNameKana, "")
    }

    /// 住所欄が1つしかないフォーム向けに、結合した住所も持つ
    func testFullAddressJoinsParts() {
        let profile = Profile()
        profile.address1 = "東京都千代田区丸の内"
        profile.address2 = "1-1-1 サンプルマンション101"

        XCTAssertEqual(profile.fullAddress, "東京都千代田区丸の内1-1-1 サンプルマンション101")
    }

    // MARK: - 永続化

    /// プロフィールは1件だけ。挿入して読み戻せること
    @MainActor
    func testProfileIsPersistedAsSingleRecord() throws {
        let container = try ModelContainer(
            for: Profile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let profile = Profile()
        profile.familyName = "鈴木"
        profile.university = "△△大学"
        context.insert(profile)

        let fetched = try context.fetch(FetchDescriptor<Profile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.familyName, "鈴木")
        XCTAssertEqual(fetched.first?.university, "△△大学")
    }

    /// 資格と URL は Codable な構造体の配列として、順序を保ったまま保存される
    @MainActor
    func testCertificationsAndLinksRoundTripInOrder() throws {
        let container = try ModelContainer(
            for: Profile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let profile = Profile()
        profile.certifications = [
            Certification(name: "TOEIC 850点", acquiredOn: date(2025, 6, 1)),
            Certification(name: "基本情報技術者", acquiredOn: date(2024, 11, 1)),
        ]
        profile.links = [
            ProfileLink(label: "GitHub", urlString: "https://github.com/example"),
            ProfileLink(label: "ポートフォリオ", urlString: "https://example.com"),
        ]
        context.insert(profile)

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<Profile>()).first)
        XCTAssertEqual(fetched.certifications.map(\.name), ["TOEIC 850点", "基本情報技術者"])
        XCTAssertEqual(fetched.links.map(\.label), ["GitHub", "ポートフォリオ"])
        XCTAssertEqual(fetched.certifications.first?.acquiredOn?.formattedYearMonth, "2025年6月")
    }
}
