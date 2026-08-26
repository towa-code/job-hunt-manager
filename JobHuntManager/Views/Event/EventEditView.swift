import SwiftUI
import SwiftData

/// 予定の新規追加・編集フォーム
struct EventEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let company: Company
    /// nilなら新規追加、値があれば編集
    let event: JobEvent?

    @State private var title: String = ""
    @State private var type: EventType = .other
    @State private var date: Date = Date()
    @State private var place: String = ""
    @State private var memo: String = ""

    private var isEditing: Bool { event != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル", text: $title)
                    Picker("種別", selection: $type) {
                        ForEach(EventType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    DatePicker("日時", selection: $date)
                    TextField("場所・URL（任意）", text: $place)
                }

                Section {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                } header: {
                    Text("メモ")
                        .font(.heading(13))
                        .foregroundStyle(.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(isEditing ? "予定を編集" : "予定を追加")
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
        guard let event else { return }
        title = event.title
        type = event.type
        date = event.date
        place = event.place
        memo = event.memo
    }

    private func save() {
        if let event {
            event.title = title
            event.type = type
            event.date = date
            event.place = place
            event.memo = memo
        } else {
            let newEvent = JobEvent(
                title: title,
                type: type,
                date: date,
                place: place,
                memo: memo,
                company: company
            )
            modelContext.insert(newEvent)
        }
        dismiss()
    }
}

#Preview {
    EventEditView(company: Company(name: "サンプル株式会社"), event: nil)
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
