import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            StepTrackingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StepData.self], inMemory: true)
}