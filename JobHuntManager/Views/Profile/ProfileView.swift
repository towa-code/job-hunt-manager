import SwiftUI
import SwiftData
import UIKit

/// 自分のプロフィール。ES・応募フォームへ転記するための表示専用画面
///
/// 値の行をタップするとクリップボードにコピーされる。入力が空の項目は行ごと出さない
/// （転記元として使うので、埋まっているものだけが並んでいるほうが目的の値を探しやすい）。
struct ProfileView: View {
    @Query private var profiles: [Profile]
    @State private var isEditing = false
    /// コピー直後に出す一時表示。項目名を入れて「何をコピーしたか」が分かるようにする
    @State private var copiedLabel: String?
    /// 連続でコピーしたときに、前回の消灯タイマーで今回の表示が消えないようにする
    @State private var copyResetTask: Task<Void, Never>?

    /// プロフィールは1件だけ。未作成なら nil
    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader(title: "あなた") {
                    if let profile, !profile.isEmpty {
                        Button {
                            isEditing = true
                        } label: {
                            Label("編集", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(SecondaryCapsuleButtonStyle())
                    }
                }

                if let profile, !profile.isEmpty {
                    profileList(profile)
                } else {
                    emptyState
                }
            }
            .background(AppBackground())
            .sheet(isPresented: $isEditing) {
                ProfileEditView(profile: profile)
            }
        }
        .overlay(alignment: .bottom) {
            if let copiedLabel {
                CopiedToast(label: copiedLabel)
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: copiedLabel)
    }

    // MARK: - 空状態

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "person.text.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(.textSecondary)

            Text("プロフィールが未登録です")
                .font(.heading(16))
                .foregroundStyle(.textPrimary)

            Text("氏名や大学名を登録しておくと、ES や応募フォームの入力欄へ\nタップひとつで転記できます。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textSecondary)

            Button("プロフィールを作成") { isEditing = true }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                .padding(.top, 4)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 本体

    private func profileList(_ profile: Profile) -> some View {
        List {
            section("基本情報") {
                copyRow("姓", profile.familyName)
                copyRow("名", profile.givenName)
                copyRow("氏名", profile.fullName)
                copyRow("セイ", profile.familyNameKana)
                copyRow("メイ", profile.givenNameKana)
                copyRow("フリガナ", profile.fullNameKana)
                birthdayRows(profile)
            }

            section("連絡先") {
                copyRow("郵便番号", profile.postalCode)
                copyRow("住所", profile.address1)
                copyRow("番地・建物", profile.address2)
                copyRow("住所（結合）", profile.fullAddress)
                copyRow("電話番号", profile.phone)
                copyRow("メール", profile.email)
            }

            section("学歴") {
                copyRow("大学", profile.university)
                copyRow("学部", profile.faculty)
                copyRow("学科", profile.department)
                copyRow("学籍番号", profile.studentID)
                if let graduationOn = profile.graduationOn {
                    copyRow("卒業予定", graduationOn.formattedYearMonth)
                }
            }

            if !profile.certifications.isEmpty {
                section("資格") {
                    ForEach(profile.certifications) { certification in
                        copyRow(
                            certification.acquiredOn?.formattedYearMonth ?? "取得年月なし",
                            certification.name
                        )
                    }
                }
            }

            if !profile.links.isEmpty {
                section("URL") {
                    ForEach(profile.links) { link in
                        linkRow(link)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    /// 中身が空なら見出しごと消す
    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section {
            content()
        } header: {
            Text(title)
                .font(.heading(13))
                .foregroundStyle(.textPrimary)
        }
    }

    /// 生年月日は西暦・和暦・年齢を別々の行に開く。
    /// ES の欄が和暦指定だったり年齢の併記を求めたりするので、それぞれ単体でコピーできる必要がある
    @ViewBuilder
    private func birthdayRows(_ profile: Profile) -> some View {
        if let birthday = profile.birthday {
            copyRow("生年月日", birthday.formattedDate)
            copyRow("生年月日（和暦）", birthday.formattedJapaneseEra)
            // 表示は「22歳」だが、数値欄への転記が大半なのでコピーする値は数字だけにする
            copyRow("年齢", "\(birthday.age())歳", copying: "\(birthday.age())")
        }
    }

    @ViewBuilder
    private func copyRow(_ label: String, _ value: String, copying: String? = nil) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            Button {
                copy(trimmed: copying ?? trimmed, label: label)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                        .frame(width: 96, alignment: .leading)
                    Text(value)
                        .foregroundStyle(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(Color.signal)
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.surfaceRaised)
        }
    }

    /// URL は開けるようにしつつ、コピーもできるようにする
    @ViewBuilder
    private func linkRow(_ link: ProfileLink) -> some View {
        let trimmed = link.urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            HStack(alignment: .firstTextBaseline) {
                Text(link.label.isEmpty ? "URL" : link.label)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .frame(width: 96, alignment: .leading)

                if let url = link.url {
                    Link(destination: url) {
                        Text(trimmed)
                            .foregroundStyle(Color.signal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(trimmed)
                        .foregroundStyle(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    copy(trimmed: trimmed, label: link.label.isEmpty ? "URL" : link.label)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(Color.signal)
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(Color.surfaceRaised)
        }
    }

    private func copy(trimmed: String, label: String) {
        UIPasteboard.general.string = trimmed
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        copiedLabel = label

        copyResetTask?.cancel()
        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            copiedLabel = nil
        }
    }
}

/// コピー直後に一瞬だけ出るフィードバック
private struct CopiedToast: View {
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
            Text("\(label)をコピーしました")
        }
        .font(.pillLabel)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.textPrimary.opacity(0.92), in: Capsule())
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self, Profile.self], inMemory: true)
}
