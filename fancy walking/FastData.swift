import Foundation
import SwiftData

@Model
final class FastData {
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval  // in seconds
    
    init(startDate: Date, endDate: Date, duration: TimeInterval) {
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
    }
}