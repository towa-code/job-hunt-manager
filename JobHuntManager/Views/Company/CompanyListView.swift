import SwiftUI
import SwiftData

struct CompanyListView: View {
    @Query(sort: \Company.createdAt, order: .reverse)
    private var companies: [Company]

    @State private var statusFilter: SelectionStatus?
    @State private var isShowingAddSheet = false

    private var filteredCompanies: [Company] {
        guard let statusFilter else { return companies }
        return companies.filter { $0.status == statusFilter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredCompanies.isEmpty {
                    ContentUnavailableView(
                        "企業が登録されていません",
                        systemImage: "building.2",
                        description: Text("右上の＋ボタンから企業を追加しましょう")
                    )
                    .background(AppBackground())
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
                    .background(AppBackground())
                }
            }
            .navigationTitle("企業")
            .navigationDestination(for: Company.self) { company in
                CompanyDetailView(company: company)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("すべて") { statusFilter = nil }
                        Divider()
                        ForEach(SelectionStatus.allCases.sorted { $0.sortOrder < $1.sortOrder }) { status in
                            Button(status.label) { statusFilter = status }
                        }
                    } label: {
                        Label(statusFilter?.label ?? "すべて", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
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

private struct CompanyRow: View {
    let company: Company

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(company.name)
                    .font(.heading(17))
                    .foregroundStyle(.textPrimary)
                if !company.industry.isEmpty {
                    Text(company.industry)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                PriorityDotsView(priority: company.priority)
            }
            Spacer()
            StatusPillView(status: company.status)
        }
        .cardStyle()
    }
}

#Preview {
    CompanyListView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
