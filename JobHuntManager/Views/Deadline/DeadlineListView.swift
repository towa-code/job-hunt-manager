import SwiftUI
import SwiftData

struct DeadlineListView: View {
    @Query private var submissions: [Submission]

    @State private var showOnlyUnsubmitted = true

    private var filteredSubmissions: [Submission] {
        let filtered = showOnlyUnsubmitted
            ? submissions.filter { $0.status != .submitted }
            : submissions
        return filtered.sorted { $0.deadline < $1.deadline }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSubmissions.isEmpty {
                    ContentUnavailableView(
                        "提出物がありません",
                        systemImage: "doc.text",
                        description: Text("企業詳細から提出物を追加しましょう")
                    )
                    .background(AppBackground())
                } else {
                    List(filteredSubmissions) { submission in
                        if let company = submission.company {
                            NavigationLink(value: company) {
                                DeadlineRow(submission: submission)
                            }
                            .listRowBackground(Color.surfaceRaised)
                        } else {
                            DeadlineRow(submission: submission)
                                .listRowBackground(Color.surfaceRaised)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppBackground())
                }
            }
            .navigationTitle("締切")
            .navigationDestination(for: Company.self) { company in
                CompanyDetailView(company: company)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("未提出のみ", isOn: $showOnlyUnsubmitted)
                        .toggleStyle(.button)
                        .tint(.signal)
                }
            }
        }
        .tint(.signal)
    }
}

private struct DeadlineRow: View {
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
                Text(submission.type.label)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(submission.deadline.formattedDate)
                    .font(.mono)
                    .foregroundStyle(submission.urgency.color)
                Text(submission.status.label)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

#Preview {
    DeadlineListView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
