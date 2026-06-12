import Foundation
import SwiftData

/// 予定の種別
enum EventType: String, Codable, CaseIterable, Identifiable {
    case briefing = "説明会"
    case interview = "面接"
    case writtenTest = "筆記"
    case obVisit = "OB訪問"
    case other = "その他"

    var id: String { rawValue }
    var label: String { rawValue }
}

/// 予定（説明会・面接・筆記試験など）
@Model
final class JobEvent {
    var id: UUID = UUID()
    var title: String = ""
    var type: EventType = EventType.other
    var date: Date = Date()
    var place: String = ""
    var memo: String = ""

    var company: Company?

    init(
        title: String,
        type: EventType = .other,
        date: Date = Date(),
        place: String = "",
        memo: String = "",
        company: Company? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.date = date
        self.place = place
        self.memo = memo
        self.company = company
    }
}
