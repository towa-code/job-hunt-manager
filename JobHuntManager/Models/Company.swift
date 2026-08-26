import Foundation
import SwiftData
import SwiftUI

/// 選考ステータス
enum SelectionStatus: String, Codable, CaseIterable, Identifiable {
    case interested = "興味あり"
    case applied = "エントリー"
    case esSubmitted = "ES提出"
    case writtenTest = "筆記"
    case interviewing = "面接中"
    case offer = "内定"
    case declined = "見送り"

    var id: String { rawValue }

    /// 表示用のラベル。`rawValue` は永続化値なので変えず、表示の差異はここで吸収する
    var label: String {
        switch self {
        case .writtenTest: return "テスト"
        case .interviewing: return "面接"
        default: return rawValue
        }
    }

    /// 一覧などでの並び順
    var sortOrder: Int {
        switch self {
        case .interested: return 0
        case .applied: return 1
        case .esSubmitted: return 2
        case .writtenTest: return 3
        case .interviewing: return 4
        case .offer: return 5
        case .declined: return 6
        }
    }

    /// ステータスピルのインジケータ色
    var indicatorColor: Color {
        switch self {
        case .interested: return .statusGray
        case .applied: return .statusBlue
        case .esSubmitted: return .statusCyan
        case .writtenTest: return .statusViolet
        case .interviewing: return .signal
        case .offer: return .statusGreen
        case .declined: return .statusGray
        }
    }
}

/// 選考区分
enum SelectionKind: String, Codable, CaseIterable, Identifiable {
    case fullTime = "本選考"
    case internship = "インターン"

    var id: String { rawValue }
    var label: String { rawValue }
}

/// インターンの実施方法
enum InternFormat: String, Codable, CaseIterable, Identifiable {
    case online = "オンライン"
    case inPerson = "対面"
    case hybrid = "ハイブリッド"

    var id: String { rawValue }
    var label: String { rawValue }
}

/// 企業
@Model
final class Company {
    var id: UUID = UUID()
    var name: String = ""
    var industry: String = ""
    var status: SelectionStatus = SelectionStatus.interested
    /// 志望度 0〜3
    var priority: Int = 0
    var urlString: String = ""
    /// 応募者マイページの URL。`urlString`（採用ページ）とは用途が違うので別に持つ
    var mypageURLString: String = ""
    var loginID: String = ""
    var memo: String = ""
    var createdAt: Date = Date()
    /// 選考区分の保存用。移行済みの既存行は NULL で読まれるため Optional にする。
    /// 直接触るのは `kind` のアクセサだけ。
    var kindRaw: SelectionKind?
    var internStartDate: Date?
    var internEndDate: Date?
    /// インターンの実施方法。未設定を許すので Optional のまま持つ
    var internFormat: InternFormat?

    /// 未設定（移行済みの既存行）は本選考として扱う
    var kind: SelectionKind {
        get { kindRaw ?? .fullTime }
        set { kindRaw = newValue }
    }

    /// インターンの実施期間の短縮表記。本選考や未設定なら nil
    var internPeriodLabel: String? {
        guard kind == .internship, let start = internStartDate else { return nil }
        guard let end = internEndDate,
              !Calendar.current.isDate(end, inSameDayAs: start) else {
            return start.formattedMonthDay
        }
        return "\(start.formattedMonthDay)〜\(end.formattedMonthDay)"
    }

    @Relationship(deleteRule: .cascade, inverse: \JobEvent.company)
    var events: [JobEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \Submission.company)
    var submissions: [Submission] = []

    init(
        name: String,
        industry: String = "",
        status: SelectionStatus = .interested,
        priority: Int = 0,
        urlString: String = "",
        mypageURLString: String = "",
        loginID: String = "",
        memo: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.industry = industry
        self.status = status
        self.priority = priority
        self.urlString = urlString
        self.mypageURLString = mypageURLString
        self.loginID = loginID
        self.memo = memo
        self.createdAt = Date()
    }
}
