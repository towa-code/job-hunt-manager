import Foundation

/// ホームの「今後の予定」に並ぶ項目。予定とインターンの実施期間を1本の時系列にまとめる
struct UpcomingItem: Identifiable {
    enum Content {
        case event(JobEvent)
        case internship(Company)
    }

    let content: Content
    /// インターンの実施期間中かどうか
    let isInProgress: Bool
    /// 並び替えと「今後7日」の判定に使う日付。実施期間中のインターンは当日として扱う
    let date: Date

    var id: String {
        switch content {
        case .event(let event): return "event-\(event.id)"
        case .internship(let company): return "internship-\(company.id)"
        }
    }
}

/// 予定とインターンを統合した時系列の組み立て。
/// 判定日を `now` で受け取るのは、`Date()` を直参照すると日付をまたいでも表示が更新されないため。
enum UpcomingTimeline {
    static func items(events: [JobEvent], companies: [Company], now: Date) -> [UpcomingItem] {
        let calendar = Calendar.current
        // 比較は当日0:00起点。時刻起点にすると当日分が消える
        let startOfToday = calendar.startOfDay(for: now)

        let eventItems = events
            .filter { $0.date >= startOfToday }
            .map { UpcomingItem(content: .event($0), isInProgress: false, date: $0.date) }

        let internshipItems = companies.compactMap { company -> UpcomingItem? in
            guard company.kind == .internship,
                  let start = company.internStartDate else { return nil }

            let startDay = calendar.startOfDay(for: start)
            // 終了日が未設定なら1日開催とみなす
            let endDay = calendar.startOfDay(for: company.internEndDate ?? start)
            guard endDay >= startOfToday else { return nil }

            // 実施期間中（開始済みで未終了）は当日扱いにして先頭付近に出す
            return UpcomingItem(
                content: .internship(company),
                isInProgress: startDay <= startOfToday,
                date: max(startDay, startOfToday)
            )
        }

        return (eventItems + internshipItems).sorted { $0.date < $1.date }
    }

    static func weekCount(events: [JobEvent], companies: [Company], now: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let weekLater = calendar.date(byAdding: .day, value: 7, to: startOfToday) else { return 0 }

        return items(events: events, companies: companies, now: now)
            .filter { $0.date < weekLater }
            .count
    }
}
