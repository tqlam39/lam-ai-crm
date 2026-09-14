import SwiftUI

@main
struct LamAICRMApp: App {
    @StateObject private var store = CRMStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
            .environment(\.locale, Locale(identifier: "vi_VN"))
        }
    }
}
