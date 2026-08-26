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

    private var overdue: [Submission] {
        filteredSubmissions.filter { $0.urgency == .overdue }
    }

    private var soon: [Submission] {
        filteredSubmissions.filter { $0.urgency == .soon }
    }

    private var later: [Submission] {
        filteredSubmissions.filter { $0.urgency == .normal }
    }

    private var done: [Submission] {
        filteredSubmissions.filter { $0.urgency == .done }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader(title: "締切") {
                    Menu {
                        Picker("表示", selection: $showOnlyUnsubmitted.animation()) {
                            Text("未提出のみ").tag(true)
                            Text("すべて").tag(false)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showOnlyUnsubmitted ? "未提出のみ" : "すべて")
                            Image(systemName: "chevron.down")
                        }
                        .secondaryCapsule()
                    }
                }

                Group {
                    if filteredSubmissions.isEmpty {
                        ContentUnavailableView(
                            showOnlyUnsubmitted ? "未提出の提出物はありません" : "提出物がありません",
                            systemImage: showOnlyUnsubmitted ? "checkmark.circle" : "doc.text",
                            description: Text(
                                showOnlyUnsubmitted
                                    ? "すべて提出済みです。おつかれさまでした！"
                                    : "企業詳細から提出物を追加しましょう"
                            )
                        )
                    } else {
                        List {
                            deadlineSection(title: "期限超過", items: overdue, accent: .statusRed)
                            deadlineSection(title: "3日以内", items: soon, accent: .signal)
                            deadlineSection(title: "それ以降", items: later, accent: nil)
                            deadlineSection(title: "提出済", items: done, accent: .statusGreen)
                        }
                        .scrollContentBackground(.hidden)
                .contentMargins(.top, 4, for: .scrollContent)
                    }
                }
            }
            .background(AppBackground())
            .navigationDestination(for: Company.self) { company in
                CompanyDetailView(company: company)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.signal)
    }

    @ViewBuilder
    private func deadlineSection(title: String, items: [Submission], accent: Color?) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { submission in
                    Group {
                        if let company = submission.company {
                            NavigationLink(value: company) {
                                DeadlineRow(submission: submission)
                            }
                        } else {
                            DeadlineRow(submission: submission)
                        }
                    }
                    .listRowBackground(Color.surfaceRaised)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if submission.status != .submitted {
                            Button {
                                withAnimation {
                                    submission.status = .submitted
                                }
                            } label: {
                                Label("提出済", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.statusGreen)
                        }
                    }
                }
            } header: {
                HStack(spacing: 6) {
                    if let accent {
                        Circle()
                            .fill(accent)
                            .frame(width: 6, height: 6)
                    }
                    Text(title)
                        .font(.heading(13))
                        .foregroundStyle(accent ?? .textPrimary)
                }
            }
        }
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
                Text("\(submission.type.label) ・ \(submission.status.label)")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                // 提出済みは締切までの相対表示が意味を持たないので日付だけを出す
                if submission.status != .submitted {
                    Text(submission.deadline.relativeDeadlineLabel)
                        .font(.pillLabel)
                        .foregroundStyle(submission.urgency.color)
                }
                Text(submission.deadline.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

#Preview {
    DeadlineListView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
