import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StepTrackingView()
                .tabItem {
                    Label("Steps", systemImage: "figure.walk")
                }
                .tag(0)
            
            FastingTimerView()
                .tabItem {
                    Label("Fasting", systemImage: "timer")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StepData.self], inMemory: true)
}