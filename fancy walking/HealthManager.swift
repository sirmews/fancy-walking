import Foundation
import HealthKit

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var updateWorkItem: DispatchWorkItem?
    
    @Published var todaySteps: Int = 0
    @Published var todayDistance: Double = 0.0 // in kilometers
    @Published var isAuthorized: Bool = false
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Define the types of data we want to read
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning)
        ]
        
        // Request authorization to read health data
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                
                if success {
                    self?.isAuthorized = true
                    self?.fetchTodaySteps()
                    self?.fetchTodayDistance()
                    self?.setupObservers()
                } else if let error = error {
                    print("Authorization failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchTodaySteps() {
        let stepsQuantityType = HKQuantityType(.stepCount)
        fetchTodaySumOfSample(for: stepsQuantityType, unit: .count()) { [weak self] result in
            DispatchQueue.main.async {
                self?.todaySteps = Int(result)
            }
        }
    }
    
    func fetchTodayDistance() {
        let distanceQuantityType = HKQuantityType(.distanceWalkingRunning)
        fetchTodaySumOfSample(for: distanceQuantityType, unit: .meter()) { [weak self] result in
            DispatchQueue.main.async {
                // Convert meters to kilometers
                self?.todayDistance = result / 1000
            }
        }
    }

    // This function debounces the updates to the steps and distance data
    // It prevents the data from being updated too frequently
    // default delay is 5 seconds
    private func debounce(delay: TimeInterval = 5, action: @escaping () -> Void) {
        updateWorkItem?.cancel()
        let workItem = DispatchWorkItem(block: action)
        updateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    private func fetchTodaySumOfSample(for quantityType: HKQuantityType, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let predicate = createTodayPredicate()
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                if let error = error {
                    print("Error fetching data: \(error.localizedDescription)")
                }
                return
            }
            
            completion(sum.doubleValue(for: unit))
        }
        
        healthStore.execute(query)
    }
    
    // This function creates a predicate (filter) for HealthKit queries to get today's health data
    // A predicate is a logical condition or filter that evaluates to true or false.
    // In this case we want health data that started from midnight today to the current time
    private func createTodayPredicate() -> NSPredicate {
        // Get the current calendar
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate the start of the current day i.e. midnight
        let startOfDay = calendar.startOfDay(for: now)
        
        // Create and return a HealthKit predicate that filters samples between start of today and current time
        // .strictStartDate ensures samples start exactly within this time range
        return HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
    }

    private func checkBackgroundDelivery(for quantityType: HKQuantityType, frequency: HKUpdateFrequency) {
        // Check if background delivery is enabled for steps and distance
        healthStore.enableBackgroundDelivery(for: quantityType, frequency: frequency, withCompletion: { success, error in
            if let error = error {
                print("Error enabling background delivery: \(error.localizedDescription)")
            }
        })
    }
    
    // Set up real-time observers for steps and distance
    private func setupObservers() {
        // Setup observer for steps
        let stepsType = HKQuantityType(.stepCount)
        let stepsQuery = HKObserverQuery(sampleType: stepsType, predicate: nil) { [weak self] query, completion, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }

            // Debounce the update to the steps data
            self?.debounce {
                self?.fetchTodaySteps()
            }
            completion()
        }
        
        healthStore.execute(stepsQuery)
        
        // Setup observer for distance
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        let distanceQuery = HKObserverQuery(sampleType: distanceType, predicate: nil) { [weak self] query, completion, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }
            
            self?.fetchTodayDistance()
            completion()
        }
        
        healthStore.execute(distanceQuery)
        
        checkBackgroundDelivery(for: stepsType, frequency: .immediate)
        checkBackgroundDelivery(for: distanceType, frequency: .immediate)
    }
}