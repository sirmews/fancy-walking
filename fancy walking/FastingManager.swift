import Foundation
import Combine

class FastingManager: ObservableObject {
    // Timer state
    @Published var isActive = false
    @Published var progress: CGFloat = 0.0
    @Published var elapsed: String = "00:00:00"
    @Published var statusText: String = "Ready to start"
    
    // Timer data
    @Published var lastStartDate: Date?
    @Published var lastEndDate: Date?
    @Published var lastFastDuration: String?
    
    // Timer publisher
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    private var timerSubscription: Cancellable?
    
    // Variables for calculating duration
    private var startTime: Date?
    private var endTime: Date?
    private var elapsedTime: TimeInterval = 0
    
    // Goal time in seconds (default 16 hours)
    private let goalSeconds: Double = 16 * 60 * 60
    
    var canSave: Bool {
        lastStartDate != nil && lastEndDate != nil && !isActive
    }
    
    var formattedStartTime: String {
        guard let startDate = lastStartDate else { return "Not started" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    var formattedEndTime: String? {
        guard let endDate = lastEndDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
    
    func toggleFasting() {
        if isActive {
            // Stop fasting
            stopTimer()
            isActive = false
            statusText = "Fast complete!"
            
            // Record end time
            endTime = Date()
            lastEndDate = endTime
            
            // Calculate duration for completed fast
            if let start = startTime, let end = endTime {
                let duration = end.timeIntervalSince(start)
                lastFastDuration = formatDuration(seconds: duration)
            }
        } else {
            // Start fasting
            startTimer()
            isActive = true
            statusText = "Fasting in progress"
            progress = 0.0
            
            // Record start time
            startTime = Date()
            lastStartDate = startTime
            lastEndDate = nil
            lastFastDuration = nil
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
        timerSubscription = timer.connect()
        
        timer
            .sink { [weak self] _ in
                self?.updateTimer()
            }
            .store(in: &cancellables)
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
        cancellables.removeAll()
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let now = Date()
        elapsedTime = now.timeIntervalSince(startTime)
        
        // Update progress (capped at 1.0)
        progress = min(CGFloat(elapsedTime / goalSeconds), 1.0)
        
        // Update elapsed time string
        elapsed = formatDuration(seconds: elapsedTime)
        
        // Update status based on progress
        if progress >= 1.0 {
            statusText = "Goal reached!"
        } else {
            let percentage = Int(progress * 100)
            statusText = "\(percentage)% of target"
        }
    }
    
    private func formatDuration(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let seconds = Int(seconds) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}