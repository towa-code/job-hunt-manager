import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var events: [JobEvent]
    @Query private var submissions: [Submission]

    @State private var grid = MonthGrid(containing: Date())
    @State private var selectedDay: Date? = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current

    private var markers: [Date: DayMarkers] {
        DayMarkers.markers(events: events, submissions: submissions, calendar: calendar)
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
                PageHeader(title: "カレンダー") {
                    Button("今日") {
                        withAnimation {
                            grid = MonthGrid(containing: Date())
                            selectedDay = calendar.startOfDay(for: Date())
                        }
                    }
                    .buttonStyle(SecondaryCapsuleButtonStyle())
                }

                List {
                    Section {
                        VStack(spacing: 12) {
                            monthHeader
                            weekdayHeader
                            monthGrid
                        }
                        .cardStyle()
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
            .toolbar(.hidden, for: .navigationBar)
        }
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
            ForEach(grid.days, id: \.self) { day in
                DayCell(
                    day: day,
                    isInDisplayedMonth: grid.isInDisplayedMonth(day),
                    isToday: calendar.isDateInToday(day),
                    isSelected: selectedDay == day,
                    markers: markers[day]
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    guard grid.isInDisplayedMonth(day) else { return }
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedDay = day
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectedDaySection: some View {
        if eventsOnSelectedDay.isEmpty && submissionsOnSelectedDay.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.textSecondary)
                Text(selectedDay == nil ? "日付をタップしてください" : "この日の予定・締切はありません")
                    .foregroundStyle(.textSecondary)
            }
            .font(.subheadline)
            .listRowBackground(Color.surfaceRaised)
        } else {
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
        VStack(spacing: 3) {
            Text(dayNumber)
                .font(.pillLabel)
                .foregroundStyle(numberColor)
                .frame(width: 28, height: 28)
                .background {
                    // 今日のリングは選択中も出す（初回起動は今日が選択済みのため、
                    // 排他にすると「今日」の手がかりが画面から消える）
                    Circle()
                        .fill(isSelected ? Color.textPrimary : Color.clear)
                        .overlay {
                            Circle().strokeBorder(isToday ? Color.signal : Color.clear, lineWidth: 1.5)
                        }
                }

            HStack(spacing: 3) {
                // 月外のマスにはドットを出さない
                if isInDisplayedMonth, let markers {
                    if markers.hasEvent {
                        Circle().fill(Color.statusBlue).frame(width: 5, height: 5)
                    }
                    if markers.hasOpenSubmission {
                        Circle().fill(Color.signal).frame(width: 5, height: 5)
                    }
                }
            }
            .frame(height: 5)
        }
        .frame(height: 44)
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
