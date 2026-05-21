import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab = 1
    @State private var showDailyFlow = false

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()

    var body: some View {
        ZStack {
            MainTabView(selection: $selectedTab)
                .opacity(showDailyFlow ? 0 : 1)

            if showDailyFlow {
                DailyFlowPager {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showDailyFlow = false
                        selectedTab = 1
                    }
                    refreshFlowState()
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .onAppear { refreshFlowState() }
        .onReceive(NotificationCenter.default.publisher(for: .dailyPlanDidChange)) { _ in
            refreshFlowState()
        }
    }

    private func refreshFlowState() {
        let hasPlan = (try? repository.hasPlanForCurrentQuestDay(in: context)) ?? false
        showDailyFlow = !hasPlan
    }
}

struct MainTabView: View {
    @Binding var selection: Int

    init(selection: Binding<Int> = .constant(1)) {
        _selection = selection
    }

    init() {
        _selection = .constant(1)
    }

    var body: some View {
        TabView(selection: $selection) {
            MedalCalendarView()
                .tag(0)
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }

            TodayTabRootView()
                .tag(1)
                .tabItem {
                    Label("今日", systemImage: "sun.horizon.fill")
                }

            SettingsView()
                .tag(2)
                .tabItem {
                    Label("设置", systemImage: "slider.horizontal.3")
                }
        }
        .tint(AppTheme.mainAccent)
        .onAppear { configureTabBar() }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.inkMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.inkMuted)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.mainAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.mainAccent)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
