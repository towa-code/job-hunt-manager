import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            CompanyListView()
                .tabItem {
                    Label("企業", systemImage: "building.2")
                }

            DeadlineListView()
                .tabItem {
                    Label("締切", systemImage: "clock.badge.exclamationmark")
                }
        }
        .tint(.signal)
        .toolbarBackground(Color.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.light)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self], inMemory: true)
}
