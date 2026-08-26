import SwiftUI
import SwiftData

/// 提出物の新規追加・編集フォーム
struct SubmissionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let company: Company
    /// nilなら新規追加、値があれば編集
    let submission: Submission?

    @State private var title: String = ""
    @State private var type: SubmissionType = .entrySheet
    @State private var deadline: Date = Date()
    @State private var status: SubmissionStatus = .notStarted
    @State private var bodyMemo: String = ""

    private var isEditing: Bool { submission != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル", text: $title)
                    Picker("種別", selection: $type) {
                        ForEach(SubmissionType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    DatePicker("締切", selection: $deadline)
                    Picker("状況", selection: $status) {
                        ForEach(SubmissionStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                }

                Section {
                    TextEditor(text: $bodyMemo)
                        .frame(minHeight: 120)
                } header: {
                    Text("本文メモ")
                        .font(.heading(13))
                        .foregroundStyle(.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(isEditing ? "提出物を編集" : "提出物を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadExistingValues)
        }
        .tint(.signal)
        .preferredColorScheme(.light)
    }

    private func loadExistingValues() {
        guard let submission else { return }
        title = submission.title
        type = submission.type
        deadline = submission.deadline
        status = submission.status
        bodyMemo = submission.bodyMemo
    }

    private func save() {
        if let submission {
            submission.title = title
            submission.type = type
            submission.deadline = deadline
            submission.status = status
            submission.bodyMemo = bodyMemo
        } else {
            let newSubmission = Submission(
                title: title,
                type: type,
                deadline: deadline,
                status: status,
                bodyMemo: bodyMemo,
                company: company
            )
            modelContext.insert(newSubmission)
        }
        dismiss()
    }
}

#Preview {
    SubmissionEditView(company: Company(name: "サンプル株式会社"), submission: nil)
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
