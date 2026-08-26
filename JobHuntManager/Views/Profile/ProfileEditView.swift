import SwiftUI
import SwiftData

/// プロフィールの新規作成・編集フォーム
struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nilなら新規作成、値があれば編集
    let profile: Profile?

    // 基本情報
    @State private var familyName: String = ""
    @State private var givenName: String = ""
    @State private var familyNameKana: String = ""
    @State private var givenNameKana: String = ""
    /// 今日を初期値にすると誕生日として使い物にならないので、新卒の年齢帯から始める
    @State private var birthday = Date.defaultBirthday
    /// DatePicker は nil を扱えないので、未設定かどうかを別に持つ
    @State private var hasBirthday = false

    // 連絡先
    @State private var postalCode: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""

    // 学歴
    @State private var university: String = ""
    @State private var faculty: String = ""
    @State private var department: String = ""
    @State private var studentID: String = ""
    @State private var graduationOn = Date.defaultGraduation
    @State private var hasGraduationOn = false

    // アピール
    @State private var certifications: [Certification] = []
    @State private var links: [ProfileLink] = []

    private var isEditing: Bool { profile != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("姓", text: $familyName)
                    TextField("名", text: $givenName)
                    TextField("セイ", text: $familyNameKana)
                    TextField("メイ", text: $givenNameKana)
                    DatePicker(
                        "生年月日",
                        selection: $birthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .onChange(of: birthday) { hasBirthday = true }
                } header: {
                    sectionHeader("基本情報")
                }

                Section {
                    TextField("郵便番号", text: $postalCode)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("都道府県・市区町村", text: $address1)
                    TextField("番地・建物名", text: $address2)
                    TextField("電話番号", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("メールアドレス", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    sectionHeader("連絡先")
                }

                Section {
                    TextField("大学名", text: $university)
                    TextField("学部", text: $faculty)
                    TextField("学科", text: $department)
                    TextField("学籍番号（任意）", text: $studentID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    DatePicker("卒業予定", selection: $graduationOn, displayedComponents: .date)
                        .onChange(of: graduationOn) { hasGraduationOn = true }
                } header: {
                    sectionHeader("学歴")
                }

                Section {
                    ForEach($certifications) { $certification in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("資格・免許名", text: $certification.name)
                            DatePicker(
                                "取得年月",
                                selection: optionalDate($certification.acquiredOn),
                                displayedComponents: .date
                            )
                            .font(.caption)
                        }
                    }
                    .onDelete { certifications.remove(atOffsets: $0) }

                    Button {
                        // 新しい行は取得年月を今日で埋めておく（未設定のまま残ると表示側で年月が出ない）
                        certifications.append(Certification(acquiredOn: Date()))
                    } label: {
                        Label("資格を追加", systemImage: "plus.circle")
                    }
                } header: {
                    sectionHeader("資格")
                }

                Section {
                    ForEach($links) { $link in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("ラベル（GitHub など）", text: $link.label)
                            TextField("URL", text: $link.urlString)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.caption)
                        }
                    }
                    .onDelete { links.remove(atOffsets: $0) }

                    Button {
                        links.append(ProfileLink())
                    } label: {
                        Label("URLを追加", systemImage: "plus.circle")
                    }
                } header: {
                    sectionHeader("URL")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(isEditing ? "プロフィールを編集" : "プロフィールを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
            .onAppear(perform: loadExistingValues)
        }
        .tint(.signal)
        .preferredColorScheme(.light)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.heading(13))
            .foregroundStyle(.textPrimary)
    }

    /// Optional な日付を DatePicker に繋ぐ。触られるまで nil のままにしておく
    private func optionalDate(_ source: Binding<Date?>) -> Binding<Date> {
        Binding(
            get: { source.wrappedValue ?? Date() },
            set: { source.wrappedValue = $0 }
        )
    }

    private func loadExistingValues() {
        guard let profile else { return }
        familyName = profile.familyName
        givenName = profile.givenName
        familyNameKana = profile.familyNameKana
        givenNameKana = profile.givenNameKana
        // nil のときは @State の初期値のままにする。ここで代入すると
        // onChange が走って「未設定」が「今日」で確定してしまう
        if let value = profile.birthday {
            birthday = value
            hasBirthday = true
        }

        postalCode = profile.postalCode
        address1 = profile.address1
        address2 = profile.address2
        phone = profile.phone
        email = profile.email

        university = profile.university
        faculty = profile.faculty
        department = profile.department
        studentID = profile.studentID
        if let value = profile.graduationOn {
            graduationOn = value
            hasGraduationOn = true
        }

        certifications = profile.certifications
        links = profile.links
    }

    private func save() {
        let target: Profile
        if let profile {
            target = profile
        } else {
            target = Profile()
            modelContext.insert(target)
        }

        target.familyName = familyName
        target.givenName = givenName
        target.familyNameKana = familyNameKana
        target.givenNameKana = givenNameKana
        target.birthday = hasBirthday ? birthday : nil

        target.postalCode = postalCode
        target.address1 = address1
        target.address2 = address2
        target.phone = phone
        target.email = email

        target.university = university
        target.faculty = faculty
        target.department = department
        target.studentID = studentID
        target.graduationOn = hasGraduationOn ? graduationOn : nil

        // 名前も URL も空のまま残った行は保存しない
        target.certifications = certifications.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        target.links = links.filter {
            !$0.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        dismiss()
    }
}

#Preview {
    ProfileEditView(profile: nil)
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self, Profile.self], inMemory: true)
}
