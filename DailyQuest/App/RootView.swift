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
                }
                .transition(.opacity)
            }
        }
        .dailyQuestAppearance()
        .onAppear { refreshFlowState() }
        .onReceive(NotificationCenter.default.publisher(for: .dailyPlanDidChange)) { _ in
            dismissDailyFlowIfPlanExists()
        }
    }

    /// 冷启动：无今日计划则展示每日流程。
    private func refreshFlowState() {
        context.processPendingChanges()
        let hasPlan = (try? repository.hasPlanForCurrentQuestDay(in: context)) ?? false
        showDailyFlow = !hasPlan
    }

    /// 计划保存后：只关闭每日流程，避免因 SwiftData 写入延迟再次弹出流程页。
    private func dismissDailyFlowIfPlanExists() {
        context.processPendingChanges()
        guard (try? repository.hasPlanForCurrentQuestDay(in: context)) ?? false else { return }
        showDailyFlow = false
    }
}

struct MainTabView: View {
    @Binding var selection: Int
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("dailyquest.appearanceMode") private var modeRaw = AppearanceMode.system.rawValue

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
        .onChange(of: colorScheme) { _, _ in configureTabBar() }
        .onChange(of: modeRaw) { _, _ in configureTabBar() }
    }

    private func configureTabBar() {
        let palette = AppTheme.palette(for: colorScheme)
        let isDark = colorScheme == .dark
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(
            style: isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        )
        appearance.backgroundColor = UIColor(palette.tabBarBackground)
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
