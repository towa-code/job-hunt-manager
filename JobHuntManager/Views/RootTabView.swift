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

            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("あなた", systemImage: "person.crop.circle")
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
        .modelContainer(for: [Company.self, JobEvent.self, Submission.self, Profile.self], inMemory: true)
}
