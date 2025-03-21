import SwiftUI
import SwiftData

struct FastingHistoryView: View {
    @Query(sort: \FastData.startDate, order: .reverse) private var fastingSessions: [FastData]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(fastingSessions) { session in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(formattedDate(session.startDate))
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(formatDuration(seconds: session.duration))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.1))
                                )
                        }
                        
                        Text("From: \(formattedTime(session.startDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("To: \(formattedTime(session.endDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteFastingSessions)
            }
            .navigationTitle("Fasting History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .emptyState(fastingSessions.isEmpty) {
                VStack(spacing: 20) {
                    Image(systemName: "timer.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.purple.opacity(0.5))
                    
                    Text("No Fasting Sessions")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Your completed fasting sessions will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
            }
        }
    }
    
    private func deleteFastingSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = fastingSessions[index]
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController?.view.endEditing(true)
            withAnimation {
                if let modelContext = session.modelContext {
                    modelContext.delete(session)
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// Custom view modifier for empty states
extension View {
    func emptyState<Content: View>(_ isEmpty: Bool, @ViewBuilder content: @escaping () -> Content) -> some View {
        ZStack {
            self
            
            if isEmpty {
                content()
            }
        }
    }
}

#Preview {
    FastingHistoryView()
        .modelContainer(for: FastData.self, inMemory: true)
}