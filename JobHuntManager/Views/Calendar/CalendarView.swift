import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var events: [JobEvent]
    @Query private var submissions: [Submission]
    @Query private var companies: [Company]

    @State private var grid = MonthGrid(containing: Date())
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: Date())
    /// インターンの帯をタップしたときの遷移先
    @State private var selectedCompany: Company?

    private let calendar = Calendar.current

    private var markers: [Date: DayMarkers] {
        DayMarkers.markers(events: events, submissions: submissions, calendar: calendar)
    }

    /// インターンの帯を週番号で引けるようにしておく
    private var internBars: [Int: [InternBar]] {
        Dictionary(
            grouping: InternSchedule.bars(companies: companies, grid: grid, calendar: calendar),
            by: \.weekIndex
        )
    }

    private var internshipsOnSelectedDay: [Company] {
        guard let selectedDay else { return [] }
        return InternSchedule.internships(on: selectedDay, companies: companies, calendar: calendar)
    }

    private var eventsOnSelectedDay: [JobEvent] {
        guard let selectedDay else { return [] }
        return events
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDay) }
            .sorted { $0.date < $1.date }
    }

    private var submissionsOnSelectedDay: [Submission] {
        guard let selectedDay else { return [] }
        return submissions
            .filter { calendar.isDate($0.deadline, inSameDayAs: selectedDay) }
            .sorted { $0.deadline < $1.deadline }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader(title: "カレンダー")

                List {
                    Section {
                        VStack(spacing: 12) {
                            monthHeader
                            weekdayHeader
                            monthGrid
                        }
                        .contentShape(Rectangle())
                        .gesture(monthSwipe)
                        .cardStyle()
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }

                    Section {
                        selectedDaySection
                    } header: {
                        Text(selectedDay?.formattedDate ?? "日付を選択")
                            .font(.heading(13))
                            .foregroundStyle(.textPrimary)
                    }
                }
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 4, for: .scrollContent)
            }
            .background(AppBackground())
            .navigationDestination(for: Company.self) { company in
                CompanyDetailView(company: company)
            }
            .navigationDestination(item: $selectedCompany) { company in
                CompanyDetailView(company: company)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        // NavigationStack 自体に付けるのが要点。root の View に付けると
        // 企業詳細から戻ったときにも発火して、見ていた月と選択日が飛んでしまう
        .onAppear(perform: showToday)
        .tint(.signal)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            // List の行の中では、既定スタイルだと行全体が1つのタップ対象になって個々のボタンに届かない
            .buttonStyle(.borderless)

            Spacer()

            Text(grid.firstOfMonth.formattedYearMonth)
                .font(.heading(18))
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText())

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            // List の行の中では、既定スタイルだと行全体が1つのタップ対象になって個々のボタンに届かない
            .buttonStyle(.borderless)
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 2) {
            ForEach(grid.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        VStack(spacing: 6) {
            ForEach(0..<(grid.days.count / 7), id: \.self) { weekIndex in
                weekRow(at: weekIndex)
            }
        }
    }

    /// 1週分。帯の1段目は日付セルの下端の余白に重ねるので、行が伸びるのは2段目以降だけ
    private func weekRow(at weekIndex: Int) -> some View {
        let days = grid.days[(weekIndex * 7)..<(weekIndex * 7 + 7)]
        let bars = internBars[weekIndex] ?? []
        let laneCount = (bars.map(\.lane).max()).map { $0 + 1 } ?? 0
        let extraHeight = CGFloat(max(0, laneCount - 1)) * InternBarLanes.lanePitch

        // 帯の列と正確に揃えるため、日付の段も間隔なしの7等分にする
        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                DayCell(
                    day: day,
                    isInDisplayedMonth: grid.isInDisplayedMonth(day),
                    isToday: calendar.isDateInToday(day),
                    isSelected: selectedDay == day,
                    markers: markers[day]
                )
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard grid.isInDisplayedMonth(day) else { return }
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedDay = day
                    }
                }
            }
        }
        .frame(height: DayCell.height + extraHeight, alignment: .top)
        .overlay(alignment: .topLeading) {
            if !bars.isEmpty {
                InternBarLanes(bars: bars) { selectedCompany = $0 }
                    .padding(.top, DayCell.height - InternBarLanes.laneHeight)
            }
        }
    }

    @ViewBuilder
    private var selectedDaySection: some View {
        if internshipsOnSelectedDay.isEmpty
            && eventsOnSelectedDay.isEmpty
            && submissionsOnSelectedDay.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.textSecondary)
                Text(selectedDay == nil ? "日付をタップしてください" : "この日の予定・締切はありません")
                    .foregroundStyle(.textSecondary)
            }
            .font(.subheadline)
            .listRowBackground(Color.surfaceRaised)
        } else {
            // 終日にかかるインターンを先に置き、時刻を持つ予定・締切をその下に並べる
            ForEach(internshipsOnSelectedDay) { company in
                companyLink(company) {
                    DayInternshipRow(company: company)
                }
            }
            ForEach(eventsOnSelectedDay) { event in
                companyLink(event.company) {
                    DayEventRow(event: event)
                }
            }
            ForEach(submissionsOnSelectedDay) { submission in
                companyLink(submission.company) {
                    DaySubmissionRow(submission: submission)
                }
            }
        }
    }

    /// 企業が紐づいていればその詳細へ、いなければただの行として出す
    @ViewBuilder
    private func companyLink<Content: View>(
        _ company: Company?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let company {
            NavigationLink(value: company) {
                content()
            }
            .listRowBackground(Color.surfaceRaised)
        } else {
            content()
                .listRowBackground(Color.surfaceRaised)
        }
    }

    /// カード上の横スワイプで月を送る
    ///
    /// `List` の縦スクロールと取り合いになるので、横方向が優勢なドラッグだけ拾う。
    /// `minimumDistance` があるため、日付セルや帯のタップは従来どおり通る。
    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                changeMonth(by: value.translation.width < 0 ? 1 : -1)
            }
    }

    /// 今日を含む月を出し、今日を選択する
    private func showToday() {
        grid = MonthGrid(containing: Date())
        selectedDay = calendar.startOfDay(for: Date())
    }

    private func changeMonth(by months: Int) {
        withAnimation {
            grid = grid.adding(months: months)
            // 表示月が変われば選択日は月外になるので解除する
            selectedDay = nil
        }
    }
}

/// 月グリッドの1マス
private struct DayCell: View {
    /// 数字＋ドットで使うのは上から 35pt。残りはインターンの帯1段目の置き場になる
    /// （帯は下端から 12pt なので、ドットとの間に 9pt 空く）
    static let height: CGFloat = 56

    let day: Date
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let markers: DayMarkers?

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: day))"
    }

    private var numberColor: Color {
        if isSelected { return .surfaceRaised }
        return isInDisplayedMonth ? .textPrimary : .textSecondary.opacity(0.35)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.pillLabel)
                .foregroundStyle(numberColor)
                .frame(width: 24, height: 24)
                .background {
                    // 選択中は塗り、今日は枠線。どちらもシグナルカラーなので、
                    // 今日を選択しているときはリングが塗りに溶ける（それでも今日と分かる）
                    Circle()
                        .fill(isSelected ? Color.signal : Color.clear)
                        .overlay {
                            Circle().strokeBorder(isToday ? Color.signal : Color.clear, lineWidth: 1.5)
                        }
                }

            HStack(spacing: 4) {
                // 月外のマスにはドットを出さない
                if isInDisplayedMonth, let markers {
                    if markers.hasEvent {
                        Circle().fill(Color.statusBlue).frame(width: 7, height: 7)
                    }
                    if markers.hasOpenSubmission {
                        Circle().fill(Color.signal).frame(width: 7, height: 7)
                    }
                }
            }
            .frame(height: 7)
        }
        .frame(height: Self.height, alignment: .top)
    }
}

/// 1週分のインターンの帯。週の幅を7等分し、開始列とレーンで配置する
private struct InternBarLanes: View {
    static let laneHeight: CGFloat = 12
    static let laneSpacing: CGFloat = 2
    /// 1段ぶんの送り幅
    static var lanePitch: CGFloat { laneHeight + laneSpacing }

    let bars: [InternBar]
    /// List の中の `NavigationLink` には開示インジケータが付いてしまうので、遷移は呼び出し側に任せる
    let onSelect: (Company) -> Void

    private var laneCount: Int {
        (bars.map(\.lane).max() ?? 0) + 1
    }

    var body: some View {
        GeometryReader { proxy in
            let columnWidth = proxy.size.width / 7

            ForEach(bars) { bar in
                InternBarView(bar: bar)
                    .padding(.horizontal, 1)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(bar.company) }
                    .frame(width: columnWidth * CGFloat(bar.columnSpan), height: Self.laneHeight)
                    .offset(
                        x: columnWidth * CGFloat(bar.startColumn),
                        y: Self.lanePitch * CGFloat(bar.lane)
                    )
            }
        }
        .frame(
            height: Self.laneHeight * CGFloat(laneCount)
                + Self.laneSpacing * CGFloat(laneCount - 1)
        )
    }
}

/// インターン実施期間の帯1本。企業名が入りきらなければ末尾を切る
private struct InternBarView: View {
    let bar: InternBar

    private let cornerRadius: CGFloat = 4

    var body: some View {
        Text(bar.company.name)
            .font(.barLabel)
            .foregroundStyle(.surfaceRaised)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.internBadge)
            .clipShape(shape)
    }

    /// 週をまたいで切れた側は角を丸めず、続きがあることを示す
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: bar.continuesFromPreviousWeek ? 0 : cornerRadius,
            bottomLeadingRadius: bar.continuesFromPreviousWeek ? 0 : cornerRadius,
            bottomTrailingRadius: bar.continuesToNextWeek ? 0 : cornerRadius,
            topTrailingRadius: bar.continuesToNextWeek ? 0 : cornerRadius
        )
    }
}

/// 選択日に実施中のインターン1件
private struct DayInternshipRow: View {
    let company: Company

    var body: some View {
        HStack {
            Circle()
                .fill(Color.internBadge)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(company.name)
                    .foregroundStyle(.textPrimary)
                Text(SelectionKind.internship.label)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Text(company.internPeriodLabel ?? "")
                .font(.mono)
                .foregroundStyle(.textSecondary)
        }
    }
}

private struct DayEventRow: View {
    let event: JobEvent

    var body: some View {
        HStack {
            Circle()
                .fill(Color.statusBlue)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .foregroundStyle(.textPrimary)
                if let companyName = event.company?.name {
                    Text(companyName)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.date.formattedTime)
                    .font(.mono)
                    .foregroundStyle(.textPrimary)
                Text(event.type.label)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

private struct DaySubmissionRow: View {
    let submission: Submission

    var body: some View {
        HStack {
            Circle()
                .fill(submission.status == .submitted ? Color.statusGreen : Color.signal)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.title)
                    .foregroundStyle(.textPrimary)
                if let companyName = submission.company?.name {
                    Text(companyName)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("締切")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
                Text(submission.status.label)
                    .font(.pillLabel)
                    .foregroundStyle(submission.urgency.color)
            }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
