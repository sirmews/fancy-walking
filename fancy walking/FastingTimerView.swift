import SwiftUI
import SwiftData

struct FastingTimerView: View {
    @StateObject private var fastingManager = FastingManager()
    @Environment(\.modelContext) private var modelContext
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer circle display
                    ZStack {
                        // Circle background
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                            .frame(width: 250, height: 250)
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0, to: fastingManager.progress)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: -90))
                            .frame(width: 230, height: 230)
                            .animation(.linear(duration: 0.5), value: fastingManager.progress)
                        
                        // Center content with time
                        VStack(spacing: 5) {
                            Text(fastingManager.elapsed)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(fastingManager.statusText)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Start/stop button
                    Button(action: fastingManager.toggleFasting) {
                        Text(fastingManager.isActive ? "End Fast" : "Start Fast")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 40)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: fastingManager.isActive ? [.red, .orange] : [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    }
                    .padding(.vertical, 10)
                    
                    // Fast details
                    if fastingManager.lastStartDate != nil {
                        VStack(spacing: 15) {
                            HStack {
                                StatInfoRow(
                                    title: "Started",
                                    value: fastingManager.formattedStartTime,
                                    systemImage: "clock"
                                )
                                
                                if let endTime = fastingManager.formattedEndTime {
                                    StatInfoRow(
                                        title: "Ended",
                                        value: endTime,
                                        systemImage: "clock.badge.checkmark"
                                    )
                                }
                            }
                            
                            if !fastingManager.isActive, let duration = fastingManager.lastFastDuration {
                                StatInfoRow(
                                    title: "Duration",
                                    value: duration,
                                    systemImage: "hourglass"
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Fasting Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if fastingManager.canSave {
                        Button(action: saveCompletedFast) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHistory = true }) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                FastingHistoryView()
            }
        }
    }
    
    private func saveCompletedFast() {
        guard let startDate = fastingManager.lastStartDate,
              let endDate = fastingManager.lastEndDate,
              !fastingManager.isActive else {
            return
        }
        
        // Create and save FastData model
        let newFastData = FastData(
            startDate: startDate,
            endDate: endDate, 
            duration: endDate.timeIntervalSince(startDate)
        )
        
        modelContext.insert(newFastData)
        try? modelContext.save()
    }
}

struct StatInfoRow: View {
    var title: String
    var value: String
    var systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    FastingTimerView()
        .modelContainer(for: [FastData.self], inMemory: true)
}