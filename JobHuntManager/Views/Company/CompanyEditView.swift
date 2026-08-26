import SwiftUI
import SwiftData

/// 企業の新規追加・編集フォーム
struct CompanyEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nilなら新規追加、値があれば編集
    let company: Company?

    @State private var name: String = ""
    @State private var industry: String = ""
    @State private var status: SelectionStatus = .interested
    @State private var kind: SelectionKind = .fullTime
    @State private var internStartDate = Date()
    @State private var internEndDate = Date()
    @State private var priority: Int = 0
    @State private var urlString: String = ""
    @State private var memo: String = ""

    private var isEditing: Bool { company != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("企業名", text: $name)
                    TextField("業界（任意）", text: $industry)
                    TextField("URL（任意）", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                Section("選考区分") {
                    Picker("区分", selection: $kind) {
                        ForEach(SelectionKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    if kind == .internship {
                        DatePicker("開始日", selection: $internStartDate, displayedComponents: .date)
                        DatePicker(
                            "終了日",
                            selection: $internEndDate,
                            in: internStartDate...,
                            displayedComponents: .date
                        )
                    }
                }

                Section("選考状況") {
                    Picker("ステータス", selection: $status) {
                        ForEach(SelectionStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }) { status in
                            Text(status.label(for: kind)).tag(status)
                        }
                    }

                    HStack {
                        Text("志望度")
                        Spacer()
                        HStack(spacing: 10) {
                            ForEach(1...3, id: \.self) { level in
                                Button {
                                    // 同じドットを再タップしたら一段下げられるようにする
                                    priority = (priority == level) ? level - 1 : level
                                } label: {
                                    Circle()
                                        .fill(level <= priority ? Color.signal : Color.surfaceBorder)
                                        .frame(width: 18, height: 18)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 100)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(isEditing ? "企業を編集" : "企業を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadExistingValues)
        }
        .tint(.signal)
        .preferredColorScheme(.light)
    }

    private func loadExistingValues() {
        guard let company else { return }
        name = company.name
        industry = company.industry
        status = company.status
        kind = company.kind
        // 未設定なら今日を初期値にする（DatePicker は nil を扱えないため）
        internStartDate = company.internStartDate ?? Date()
        internEndDate = company.internEndDate ?? company.internStartDate ?? Date()
        priority = company.priority
        urlString = company.urlString
        memo = company.memo
    }

    private func save() {
        if let company {
            company.name = name
            company.industry = industry
            company.status = status
            company.priority = priority
            company.urlString = urlString
            company.memo = memo
            applyKind(to: company)
        } else {
            let newCompany = Company(
                name: name,
                industry: industry,
                status: status,
                priority: priority,
                urlString: urlString,
                memo: memo
            )
            applyKind(to: newCompany)
            modelContext.insert(newCompany)
        }
        dismiss()
    }

    /// 本選考に戻したときは実施期間を落とす（インターンでない企業に期間が残らないように）
    private func applyKind(to company: Company) {
        company.kind = kind
        if kind == .internship {
            company.internStartDate = internStartDate
            company.internEndDate = internEndDate
        } else {
            company.internStartDate = nil
            company.internEndDate = nil
        }
    }
}

#Preview {
    CompanyEditView(company: nil)
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
