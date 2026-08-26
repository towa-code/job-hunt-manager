import Foundation
import SwiftData

/// 資格・免許の1行
///
/// `Profile` の属性としてまとめて保存する。単体で検索・集計する用途がないので、
/// リレーション（別 `@Model`）にはせず Codable な構造体の配列で持つ。配列の順序がそのまま表示順になる。
struct Certification: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    /// 例: "TOEIC 850点" "基本情報技術者"
    var name: String = ""
    /// 取得年月。日は使わず年月だけ表示する
    var acquiredOn: Date?

    init(id: UUID = UUID(), name: String = "", acquiredOn: Date? = nil) {
        self.id = id
        self.name = name
        self.acquiredOn = acquiredOn
    }
}

/// GitHub やポートフォリオなどの URL の1行
struct ProfileLink: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    /// 例: "GitHub" "ポートフォリオ"
    var label: String = ""
    var urlString: String = ""

    init(id: UUID = UUID(), label: String = "", urlString: String = "") {
        self.id = id
        self.label = label
        self.urlString = urlString
    }

    /// `Link` に渡せる URL。スキームが無ければ https を補う
    var url: URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("://") { return URL(string: trimmed) }
        return URL(string: "https://\(trimmed)")
    }
}

/// 自分のプロフィール。ES・応募フォームへの転記元として使う
///
/// ストアには1件だけ置く。起動時に空レコードを作らず、最初の保存で `insert` する遅延生成にしている。
@Model
final class Profile {
    // MARK: 基本情報

    /// ES の氏名欄は「姓」「名」が別々のことが多いので分けて持つ。結合形は `fullName`
    var familyName: String = ""
    var givenName: String = ""
    var familyNameKana: String = ""
    var givenNameKana: String = ""
    var birthday: Date?

    // MARK: 連絡先

    var postalCode: String = ""
    /// 都道府県・市区町村
    var address1: String = ""
    /// 番地・建物名
    var address2: String = ""
    var phone: String = ""
    var email: String = ""

    // MARK: 学歴

    var university: String = ""
    var faculty: String = ""
    var department: String = ""
    var studentID: String = ""
    /// 卒業予定年月。日は使わず年月だけ表示する
    var graduationOn: Date?

    // MARK: アピール

    var certifications: [Certification] = []
    var links: [ProfileLink] = []

    init() {}

    // MARK: 転記用の結合形

    /// 氏名欄が1つしかないフォーム向け。片方が空でも余分な空白を残さない
    var fullName: String {
        [familyName, givenName].joinedTrimmingEmpty(separator: " ")
    }

    var fullNameKana: String {
        [familyNameKana, givenNameKana].joinedTrimmingEmpty(separator: " ")
    }

    /// 住所欄が1つしかないフォーム向け。番地は市区町村に直に続くので区切り文字を入れない
    var fullAddress: String {
        [address1, address2].joinedTrimmingEmpty(separator: "")
    }

    /// 入力が1つでもあれば「作成済み」とみなす
    var isEmpty: Bool {
        fullName.isEmpty
            && fullNameKana.isEmpty
            && birthday == nil
            && postalCode.isEmpty
            && fullAddress.isEmpty
            && phone.isEmpty
            && email.isEmpty
            && university.isEmpty
            && faculty.isEmpty
            && department.isEmpty
            && studentID.isEmpty
            && graduationOn == nil
            && certifications.isEmpty
            && links.isEmpty
    }
}

private extension Array where Element == String {
    /// 空白のみの要素を落としてから連結する
    func joinedTrimmingEmpty(separator: String) -> String {
        compactMap { part -> String? in
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        .joined(separator: separator)
    }
}

extension Date {
    /// 生年月日 DatePicker の初期値。新卒の年齢帯（22歳前後）から始める
    static var defaultBirthday: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -22, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    /// 卒業予定 DatePicker の初期値。今日以降で最初の3月
    static var defaultGraduation: Date {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let components = DateComponents(year: month <= 3 ? year : year + 1, month: 3, day: 1)
        return calendar.date(from: components) ?? now
    }
}
