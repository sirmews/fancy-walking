import Foundation
import SwiftData

@Model
final class StepData {
    var date: Date
    var steps: Int
    var distance: Double // in kilometers
    
    init(date: Date, steps: Int, distance: Double) {
        self.date = date
        self.steps = steps
        self.distance = distance
    }
}