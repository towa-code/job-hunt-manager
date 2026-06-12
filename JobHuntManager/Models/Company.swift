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

    var label: String { rawValue }

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
    var memo: String = ""
    var createdAt: Date = Date()

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
        memo: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.industry = industry
        self.status = status
        self.priority = priority
        self.urlString = urlString
        self.memo = memo
        self.createdAt = Date()
    }
}
