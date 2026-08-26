import SwiftUI
import SwiftData

struct CompanyListView: View {
    @Query(sort: \Company.createdAt, order: .reverse)
    private var companies: [Company]

    @State private var statusFilter: SelectionStatus?
    @State private var searchText = ""
    @State private var isShowingAddSheet = false

    private var filteredCompanies: [Company] {
        var result = companies
        if let statusFilter {
            result = result.filter { $0.status == statusFilter }
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
                    || $0.industry.localizedCaseInsensitiveContains(trimmed)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FilterChipsRow(selection: $statusFilter)
                    .padding(.vertical, 8)

                if filteredCompanies.isEmpty {
                    ContentUnavailableView(
                        companies.isEmpty ? "企業が登録されていません" : "該当する企業がありません",
                        systemImage: "building.2",
                        description: Text(
                            companies.isEmpty
                                ? "右上の＋ボタンから企業を追加しましょう"
                                : "検索条件やフィルタを変えてみてください"
                        )
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredCompanies) { company in
                            NavigationLink(value: company) {
                                CompanyRow(company: company)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppBackground())
            .navigationTitle("企業")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "企業名・業界で検索")
            .navigationDestination(for: Company.self) { company in
                CompanyDetailView(company: company)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                CompanyEditView(company: nil)
            }
        }
        .tint(.signal)
    }
}

/// ステータスで絞り込む横スクロールのチップ列
private struct FilterChipsRow: View {
    @Binding var selection: SelectionStatus?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "すべて", isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(SelectionStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }) { status in
                    FilterChip(
                        label: status.label,
                        dotColor: status.indicatorColor,
                        isSelected: selection == status
                    ) {
                        selection = selection == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct FilterChip: View {
    let label: String
    var dotColor: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.pillLabel)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? Color.signal.opacity(0.15) : Color.surfaceRaised,
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.signal : Color.surfaceBorder,
                    lineWidth: 1
                )
            )
            .foregroundStyle(isSelected ? Color.signal : Color.textPrimary)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

private struct CompanyRow: View {
    let company: Company

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(company.name)
                        .font(.heading(17))
                        .foregroundStyle(.textPrimary)
                    if company.kind == .internship {
                        KindBadgeView(kind: company.kind)
                    }
                }
                if !company.industry.isEmpty {
                    Text(company.industry)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                if let period = company.internPeriodLabel {
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(Color.internBadge)
                }
                PriorityDotsView(priority: company.priority)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StatusPillView(status: company.status, kind: company.kind)
                if let nextEvent = company.events.filter({ $0.date >= Date() }).min(by: { $0.date < $1.date }) {
                    Text("次: \(nextEvent.date.formattedShortDateTime)")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    CompanyListView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
