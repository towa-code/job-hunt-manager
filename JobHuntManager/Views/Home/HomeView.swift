import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var companies: [Company]
    @Query private var events: [JobEvent]
    @Query private var submissions: [Submission]

    private var upcomingEvents: [JobEvent] {
        let now = Date()
        return events
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
            .prefix(5)
            .map { $0 }
    }

    private var upcomingSubmissions: [Submission] {
        submissions
            .filter { $0.status != .submitted }
            .sorted { $0.deadline < $1.deadline }
            .prefix(5)
            .map { $0 }
    }

    /// 選考が動いている企業数（内定・見送り以外）
    private var activeCompanyCount: Int {
        companies.filter { $0.status != .offer && $0.status != .declined }.count
    }

    /// 今後7日以内の予定数
    private var thisWeekEventCount: Int {
        let now = Date()
        guard let weekLater = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return 0 }
        return events.filter { $0.date >= now && $0.date <= weekLater }.count
    }

    /// 期限切れ＋3日以内の未提出物数
    private var urgentSubmissionCount: Int {
        submissions.filter {
            $0.status != .submitted && ($0.urgency == .overdue || $0.urgency == .soon)
        }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 10) {
                        SummaryCard(value: activeCompanyCount, label: "選考中", color: .signal)
                        SummaryCard(value: thisWeekEventCount, label: "今週の予定", color: .statusBlue)
                        SummaryCard(value: urgentSubmissionCount, label: "期限間近", color: .statusRed)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }

                Section {
                    if upcomingEvents.isEmpty {
                        EmptyRowLabel(text: "予定はありません", icon: "calendar")
                            .listRowBackground(Color.surfaceRaised)
                    } else {
                        ForEach(upcomingEvents) { event in
                            if let company = event.company {
                                NavigationLink(value: company) {
                                    UpcomingEventRow(event: event)
                                }
                                .listRowBackground(Color.surfaceRaised)
                            } else {
                                UpcomingEventRow(event: event)
                                    .listRowBackground(Color.surfaceRaised)
                            }
                        }
                    }
                } header: {
                    Text("今後の予定")
                        .font(.heading(13))
                        .foregroundStyle(.textSecondary)
                }

                Section {
                    if upcomingSubmissions.isEmpty {
                        EmptyRowLabel(text: "未提出の提出物はありません", icon: "checkmark.circle")
                            .listRowBackground(Color.surfaceRaised)
                    } else {
                        ForEach(upcomingSubmissions) { submission in
                            if let company = submission.company {
                                NavigationLink(value: company) {
                                    UpcomingSubmissionRow(submission: submission)
                                }
                                .listRowBackground(Color.surfaceRaised)
                            } else {
                                UpcomingSubmissionRow(submission: submission)
                                    .listRowBackground(Color.surfaceRaised)
                            }
                        }
                    }
                } header: {
                    Text("締切が近い提出物")
                        .font(.heading(13))
                        .foregroundStyle(.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("ホーム")
            .navigationDestination(for: Company.self) { company in
                CompanyDetailView(company: company)
            }
        }
        .tint(.signal)
    }
}

/// サマリー数値カード
private struct SummaryCard: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.heading(26))
                .foregroundStyle(value > 0 ? color : .textSecondary)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.surfaceBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

/// 空状態の行
private struct EmptyRowLabel: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.textSecondary)
            Text(text)
                .foregroundStyle(.textSecondary)
        }
        .font(.subheadline)
    }
}

private struct UpcomingEventRow: View {
    let event: JobEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .foregroundStyle(.textPrimary)
                if let companyName = event.company?.name {
                    Text(companyName)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.date.formattedShortDateTime)
                    .font(.mono)
                    .foregroundStyle(.textPrimary)
                Text(event.type.label)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

private struct UpcomingSubmissionRow: View {
    let submission: Submission

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.title)
                    .foregroundStyle(.textPrimary)
                if let companyName = submission.company?.name {
                    Text(companyName)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(submission.deadline.relativeDeadlineLabel)
                    .font(.pillLabel)
                    .foregroundStyle(submission.urgency.color)
                Text(submission.deadline.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
