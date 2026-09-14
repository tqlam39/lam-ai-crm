import SwiftUI

@main
struct LamAICRMApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "house.fill").font(.system(size: 48)).foregroundStyle(.teal)
                    Text("LẮM AI CRM").font(.largeTitle.bold())
                    Text("Không gian của bạn. Cơ hội của bạn.").foregroundStyle(.secondary)
                    Text("Đang chuyển các module sang iOS Native.").font(.footnote)
                }
                .padding()
                .navigationTitle("Nhà")
            }
            .environment(\.locale, Locale(identifier: "vi_VN"))
        }
    }
}
