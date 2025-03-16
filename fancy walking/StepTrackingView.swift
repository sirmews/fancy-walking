import SwiftUI
import SwiftData

// @todo: add an about page
struct StepTrackingView: View {
    @StateObject private var healthManager = HealthManager()
    @Environment(\.modelContext) private var modelContext
    // @todo: can we use this to get the most recent step data later?
    @Query private var recentStepData: [StepData]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily step counter display
                    ZStack {
                        // Circle background
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                            .frame(width: 250, height: 250)
                        
                        // Decorative ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 230, height: 230)
                        
                        // Center content
                        VStack(spacing: 5) {
                            Text("\(healthManager.todaySteps)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Steps Today")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Distance and calories
                    HStack(spacing: 20) {
                        // Distance card
                        StatCard(
                            title: "Distance",
                            value: String(format: "%.2f", healthManager.todayDistance),
                            unit: "km",
                            systemImage: "figure.walk"
                        )
                        
                        // Calories estimation card (rough estimate)
                        StatCard(
                            title: "Calories",
                            value: "\(Int(Double(healthManager.todaySteps) * 0.04))",
                            unit: "kcal",
                            systemImage: "flame.fill"
                        )
                    }
                    
                    // Health authorization status
                    if !healthManager.isAuthorized {
                        Button(action: {
                            healthManager.requestAuthorization()
                        }) {
                            Text("Authorize HealthKit Access")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Step Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveCurrentStepData) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .onAppear {
            // Refresh data when view appears
            healthManager.fetchTodaySteps()
            healthManager.fetchTodayDistance()
        }
    }
    
    private func saveCurrentStepData() {
        let newStepData = StepData(
            date: Date(),
            steps: healthManager.todaySteps,
            distance: healthManager.todayDistance
        )
        
        modelContext.insert(newStepData)
        
        try? modelContext.save()
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var unit: String
    var systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    StepTrackingView()
        .modelContainer(for: StepData.self, inMemory: true)
}