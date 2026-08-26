import SwiftUI
import SwiftData

@main
struct JobHuntManagerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Company.self,
            JobEvent.self,
            Submission.self,
            Profile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-seedSampleData") {
                Self.seedSampleData(into: container)
            }
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    #if DEBUG
    /// `-seedSampleData` 起動引数付きのときだけ、空のストアにデモデータを投入する
    @MainActor
    private static func seedSampleData(into container: ModelContainer) {
        let context = container.mainContext
        let existing = (try? context.fetchCount(FetchDescriptor<Company>())) ?? 0
        guard existing == 0 else { return }

        let calendar = Calendar.current
        func days(_ offset: Int, hour: Int = 10) -> Date {
            let day = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        let sakura = Company(name: "サクラ商事", industry: "総合商社", status: .interviewing, priority: 3, urlString: "sakura-shoji.example.com", memo: "夏インターン経由。二次面接はケース中心らしい。")
        let aoba = Company(name: "アオバテック", industry: "ITサービス", status: .esSubmitted, priority: 2)
        let hinata = Company(name: "ヒナタ銀行", industry: "金融", status: .applied, priority: 1)
        let kaede = Company(name: "カエデ製薬", industry: "メーカー", status: .offer, priority: 2)
        context.insert(sakura)
        context.insert(aoba)
        context.insert(hinata)
        context.insert(kaede)

        // カレンダーの帯を確かめられるよう、実施期間が重なり、かつ週をまたぐインターンを入れておく
        let midori = Company(name: "ミドリ物産", industry: "食品", status: .applied, priority: 2)
        midori.kind = .internship
        midori.internStartDate = days(-4)
        midori.internEndDate = days(1)
        midori.internFormat = .inPerson

        let kohaku = Company(name: "コハク工業", industry: "メーカー", status: .interested, priority: 1)
        kohaku.kind = .internship
        kohaku.internStartDate = days(-1)
        kohaku.internEndDate = days(4)
        kohaku.internFormat = .online

        context.insert(midori)
        context.insert(kohaku)

        context.insert(JobEvent(title: "二次面接", type: .interview, date: days(2, hour: 14), place: "本社 12F", company: sakura))
        context.insert(JobEvent(title: "OB訪問", type: .obVisit, date: days(5, hour: 18), place: "オンライン", company: sakura))
        context.insert(JobEvent(title: "Webテスト", type: .test, date: days(4, hour: 9), company: hinata))
        context.insert(JobEvent(title: "会社説明会", type: .briefing, date: days(9, hour: 13), place: "Zoom", company: aoba))

        context.insert(Submission(title: "本選考ES", type: .entrySheet, deadline: days(-1), status: .inProgress, company: hinata))
        context.insert(Submission(title: "二次面接前アンケート", type: .other, deadline: days(1), status: .notStarted, company: sakura))
        context.insert(Submission(title: "履歴書", type: .resume, deadline: days(6), status: .notStarted, company: aoba))
        context.insert(Submission(title: "インターンES", type: .entrySheet, deadline: days(-7), status: .submitted, company: kaede))

        let profile = Profile()
        profile.familyName = "鈴木"
        profile.givenName = "太郎"
        profile.familyNameKana = "スズキ"
        profile.givenNameKana = "タロウ"
        profile.birthday = calendar.date(from: DateComponents(year: 2003, month: 4, day: 1))
        profile.postalCode = "100-0005"
        profile.address1 = "東京都千代田区丸の内"
        profile.address2 = "1-1-1 サンプルマンション101"
        profile.phone = "090-1234-5678"
        profile.email = "taro.suzuki@example.com"
        profile.university = "△△大学"
        profile.faculty = "工学部"
        profile.department = "情報工学科"
        profile.studentID = "S2100123"
        profile.graduationOn = calendar.date(from: DateComponents(year: 2027, month: 3, day: 1))
        profile.certifications = [
            Certification(name: "TOEIC 850点", acquiredOn: calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))),
            Certification(name: "基本情報技術者", acquiredOn: calendar.date(from: DateComponents(year: 2024, month: 11, day: 1))),
        ]
        profile.links = [
            ProfileLink(label: "GitHub", urlString: "https://github.com/example"),
            ProfileLink(label: "ポートフォリオ", urlString: "https://example.com"),
        ]
        context.insert(profile)
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
