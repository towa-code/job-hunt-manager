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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if upcomingEvents.isEmpty {
                        Text("予定はありません")
                            .foregroundStyle(.textSecondary)
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
                        Text("提出物はありません")
                            .foregroundStyle(.textSecondary)
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
                Text(submission.deadline.formattedDate)
                    .font(.mono)
                    .foregroundStyle(submission.urgency.color)
                Text(submission.status.label)
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
