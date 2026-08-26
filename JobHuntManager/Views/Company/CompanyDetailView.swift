import SwiftUI
import SwiftData

struct CompanyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var company: Company

    @State private var isShowingEditCompany = false
    @State private var isShowingAddEvent = false
    @State private var isShowingAddSubmission = false
    @State private var editingEvent: JobEvent?
    @State private var editingSubmission: Submission?
    @State private var isShowingDeleteConfirmation = false

    private var sortedEvents: [JobEvent] {
        company.events.sorted { $0.date < $1.date }
    }

    private var sortedSubmissions: [Submission] {
        company.submissions.sorted { $0.deadline < $1.deadline }
    }

    /// URL文字列をスキーム付きのURLに正規化（スキームがなければ https を補う）
    private func normalizedURL(_ urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }

    /// 削除確認ダイアログの本文。子データがあるときだけ件数を添える
    private var deleteConfirmationMessage: String {
        var children: [String] = []
        if !company.events.isEmpty { children.append("予定 \(company.events.count)件") }
        if !company.submissions.isEmpty { children.append("提出物 \(company.submissions.count)件") }

        var message = "「\(company.name)」を削除します。"
        if !children.isEmpty {
            message += "紐づく\(children.joined(separator: "・"))も削除されます。"
        }
        return message + "この操作は取り消せません。"
    }

    /// 応募者マイページ。URL・ログインIDのどちらも未入力なら丸ごと出さない
    @ViewBuilder
    private var mypageSection: some View {
        if normalizedURL(company.mypageURLString) != nil || !company.loginID.isEmpty {
            Section {
                if let url = normalizedURL(company.mypageURLString) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.square")
                                .font(.caption)
                            Text(company.mypageURLString)
                                .font(.mono)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.signal)
                    }
                    .listRowBackground(Color.surfaceRaised)
                }

                if !company.loginID.isEmpty {
                    HStack(spacing: 8) {
                        Text("ログインID")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                        Text(company.loginID)
                            .font(.mono)
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = company.loginID
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.signal)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("ログインIDをコピー")
                    }
                    .listRowBackground(Color.surfaceRaised)
                }
            } header: {
                Text("マイページ")
                    .font(.heading(13))
                    .foregroundStyle(.textPrimary)
            }
        }
    }

    /// Listのbodyが型チェックの予算を超えるため、削除セクションは切り出す
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("この企業を削除", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(Color.statusRed)
            }
            .listRowBackground(Color.surfaceRaised)
        }
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
                            if company.kind == .internship {
                                KindBadgeView(kind: company.kind)
                            }
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

                    if let period = company.internPeriodLabel {
                        HStack(spacing: 8) {
                            Text("実施期間")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                            Text(period)
                                .font(.mono)
                                .foregroundStyle(Color.internBadge)
                        }
                    }

                    if company.kind == .internship, let format = company.internFormat {
                        HStack(spacing: 8) {
                            Text("実施方法")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                            Text(format.label)
                                .font(.caption)
                                .foregroundStyle(Color.internBadge)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("志望度")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                        PriorityDotsView(priority: company.priority)
                    }

                    if let url = normalizedURL(company.urlString) {
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

            mypageSection

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
                    .foregroundStyle(.textPrimary)
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
                    .foregroundStyle(.textPrimary)
            }

            deleteSection
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
        .confirmationDialog(
            "この企業を削除しますか？",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { deleteCompany() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
    }

    /// 先に画面を閉じてから削除する。逆順にすると、削除済みの `company` を
    /// まだ表示中のこのViewが参照してクラッシュしうる
    private func deleteCompany() {
        dismiss()
        DispatchQueue.main.async {
            modelContext.delete(company)
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
