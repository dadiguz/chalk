import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @Environment(RoutineStore.self) private var store
    @State private var selectedTab = AppTab.today
    @State private var isCheckInPresented = false
    @State private var isOnboarding = false
    @State private var isShowingSplash = true

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Mi día", systemImage: "checklist", value: .today) {
                TodayView()
            }
            Tab("Plan", systemImage: "calendar", value: .plan) {
                PlanView()
            }
            Tab("Perfil", systemImage: "person.crop.circle", value: .profile) {
                ProfileView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .overlay {
            if isShowingSplash {
                SplashView {
                    isShowingSplash = false
                    isOnboarding = profiles.isEmpty
                    checkWeekly()
                }
            }
        }
        .fullScreenCover(isPresented: $isOnboarding) {
            OnboardingWizard()
        }
        .sheet(isPresented: $isCheckInPresented) {
            if let profile = profiles.first {
                WeeklyCheckInView(profile: profile)
            }
        }
        .task {
            await WorkoutSession.shared.restore()
            #if DEBUG
            DebugSeeder.seedIfRequested(context: context, store: store)
            switch UserDefaults.standard.string(forKey: "tab") {
            case "plan": selectedTab = .plan
            case "profile": selectedTab = .profile
            default: break
            }
            #endif
        }
        .onChange(of: profiles.isEmpty, initial: true) { _, isEmpty in
            isOnboarding = isEmpty && !isShowingSplash
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { checkWeekly() }
        }
    }

    private func checkWeekly() {
        guard !isShowingSplash, !isOnboarding, let profile = profiles.first, profile.needsWeeklyCheckIn() else { return }
        isCheckInPresented = true
    }
}
