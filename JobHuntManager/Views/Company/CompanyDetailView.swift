import SwiftUI
import SwiftData

struct CompanyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var company: Company

    @State private var isShowingEditCompany = false
    @State private var isShowingAddEvent = false
    @State private var isShowingAddSubmission = false
    @State private var editingEvent: JobEvent?
    @State private var editingSubmission: Submission?

    private var sortedEvents: [JobEvent] {
        company.events.sorted { $0.date < $1.date }
    }

    private var sortedSubmissions: [Submission] {
        company.submissions.sorted { $0.deadline < $1.deadline }
    }

    /// URL文字列をスキーム付きのURLに正規化（スキームがなければ https を補う）
    private var normalizedURL: URL? {
        let trimmed = company.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(company.name)
                                .font(.heading(22))
                                .foregroundStyle(.textPrimary)
                            if !company.industry.isEmpty {
                                Text(company.industry)
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                        Spacer()
                        Menu {
                            ForEach(SelectionStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }) { status in
                                Button {
                                    withAnimation { company.status = status }
                                } label: {
                                    if status == company.status {
                                        Label(status.label, systemImage: "checkmark")
                                    } else {
                                        Text(status.label)
                                    }
                                }
                            }
                        } label: {
                            StatusPillView(status: company.status)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("志望度")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                        PriorityDotsView(priority: company.priority)
                    }

                    if let url = normalizedURL {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.caption)
                                Text(company.urlString)
                                    .font(.mono)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.signal)
                        }
                    }

                    if !company.memo.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("メモ")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                            Text(company.memo)
                                .foregroundStyle(.textPrimary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.surfaceRaised)
            }

            Section {
                if sortedEvents.isEmpty {
                    Text("予定はありません")
                        .foregroundStyle(.textSecondary)
                        .listRowBackground(Color.surfaceRaised)
                } else {
                    ForEach(sortedEvents) { event in
                        Button {
                            editingEvent = event
                        } label: {
                            EventRow(event: event)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.surfaceRaised)
                    }
                    .onDelete(perform: deleteEvents)
                }
                Button {
                    isShowingAddEvent = true
                } label: {
                    Label("予定を追加", systemImage: "plus")
                        .foregroundStyle(.signal)
                }
                .listRowBackground(Color.surfaceRaised)
            } header: {
                Text("予定")
                    .font(.heading(13))
                    .foregroundStyle(.textSecondary)
            }

            Section {
                if sortedSubmissions.isEmpty {
                    Text("提出物はありません")
                        .foregroundStyle(.textSecondary)
                        .listRowBackground(Color.surfaceRaised)
                } else {
                    ForEach(sortedSubmissions) { submission in
                        Button {
                            editingSubmission = submission
                        } label: {
                            SubmissionRow(submission: submission)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.surfaceRaised)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if submission.status != .submitted {
                                Button {
                                    withAnimation { submission.status = .submitted }
                                } label: {
                                    Label("提出済", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.statusGreen)
                            }
                        }
                    }
                    .onDelete(perform: deleteSubmissions)
                }
                Button {
                    isShowingAddSubmission = true
                } label: {
                    Label("提出物を追加", systemImage: "plus")
                        .foregroundStyle(.signal)
                }
                .listRowBackground(Color.surfaceRaised)
            } header: {
                Text("提出物")
                    .font(.heading(13))
                    .foregroundStyle(.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(company.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { isShowingEditCompany = true }
                    .tint(.signal)
            }
        }
        .sheet(isPresented: $isShowingEditCompany) {
            CompanyEditView(company: company)
        }
        .sheet(isPresented: $isShowingAddEvent) {
            EventEditView(company: company, event: nil)
        }
        .sheet(isPresented: $isShowingAddSubmission) {
            SubmissionEditView(company: company, submission: nil)
        }
        .sheet(item: $editingEvent) { event in
            EventEditView(company: company, event: event)
        }
        .sheet(item: $editingSubmission) { submission in
            SubmissionEditView(company: company, submission: submission)
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedEvents[index])
        }
    }

    private func deleteSubmissions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedSubmissions[index])
        }
    }
}

private struct EventRow: View {
    let event: JobEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .foregroundStyle(.textPrimary)
                Text(event.type.label)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Text(event.date.formattedShortDateTime)
                .font(.mono)
                .foregroundStyle(.textSecondary)
        }
    }
}

private struct SubmissionRow: View {
    let submission: Submission

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.title)
                    .foregroundStyle(.textPrimary)
                Text(submission.type.label)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(submission.status == .submitted ? "提出済" : submission.deadline.relativeDeadlineLabel)
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
    NavigationStack {
        CompanyDetailView(company: Company(name: "サンプル株式会社"))
    }
    .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
