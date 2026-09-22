import SwiftData
import SwiftUI

@main
struct ChalkApp: App {
    @State private var store = AppServices.routineStore

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
        .modelContainer(AppServices.modelContainer)
    }
}
