import Foundation
import SwiftData
import SwiftUI

/// 提出物の種別
enum SubmissionType: String, Codable, CaseIterable, Identifiable {
    case entrySheet = "ES"
    case resume = "履歴書"
    case other = "その他"

    var id: String { rawValue }
    var label: String { rawValue }
}

/// 提出物のステータス
enum SubmissionStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "未着手"
    case inProgress = "作成中"
    case submitted = "提出済"

    var id: String { rawValue }
    var label: String { rawValue }
}

/// 締切の緊急度
enum SubmissionUrgency {
    case done
    case overdue
    case soon
    case normal

    var color: Color {
        switch self {
        case .done: return .textSecondary
        case .overdue: return .statusRed
        case .soon: return .signal
        case .normal: return .textPrimary
        }
    }
}

/// 提出物（ES・履歴書など）
@Model
final class Submission {
    var id: UUID = UUID()
    var title: String = ""
    var type: SubmissionType = SubmissionType.entrySheet
    var deadline: Date = Date()
    var status: SubmissionStatus = SubmissionStatus.notStarted
    var bodyMemo: String = ""

    var company: Company?

    init(
        title: String,
        type: SubmissionType = .entrySheet,
        deadline: Date = Date(),
        status: SubmissionStatus = .notStarted,
        bodyMemo: String = "",
        company: Company? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.deadline = deadline
        self.status = status
        self.bodyMemo = bodyMemo
        self.company = company
    }

    /// 締切の緊急度（提出済なら done、期限切れなら overdue、3日以内なら soon）
    var urgency: SubmissionUrgency {
        if status == .submitted {
            return .done
        }
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let deadlineDay = calendar.date(
            byAdding: .day,
            value: 3,
            to: startOfToday
        ) else {
            return .normal
        }

        if deadline < startOfToday {
            return .overdue
        } else if deadline < deadlineDay {
            return .soon
        } else {
            return .normal
        }
    }
}
