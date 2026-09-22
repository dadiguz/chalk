import SwiftData
import SwiftUI

@main
struct ChalkApp: App {
    @State private var store = RoutineStore()

    init() {
        FontRegistry.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "es_MX"))
                .environment(\.calendar, .chalk)
        }
        .modelContainer(for: [
            WorkoutEntry.self,
            ExerciseSetting.self,
            Note.self,
            MakeupSession.self,
            UserProfile.self,
            BodyWeightEntry.self,
            ProgressPhoto.self,
        ])
    }
}
