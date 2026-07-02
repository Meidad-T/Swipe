import Foundation
import CoreLocation
import os
import Combine

#if os(iOS)
class SpatialTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = SpatialTracker()
    
    private let locationManager = CLLocationManager()
    let logger = Logger(subsystem: "com.swipe", category: "SpatialTracker")
    
    @Published var currentHeading: Double = 0.0
    
    // A hypothetical angle where the Mac is located (e.g. 0.0 for North)
    // In a full implementation, this would be calibrated by the user.
    @Published var targetMacHeading: Double = 0.0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            logger.info("Started updating heading")
        } else {
            logger.warning("Heading is not available on this device.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.currentHeading = newHeading.magneticHeading
        }
    }
    
    // Check if we are pointing towards the Mac (within a +/- 20 degree window)
    func isPointingAtMac() -> Bool {
        let difference = abs(currentHeading - targetMacHeading)
        let shortestDifference = min(difference, 360 - difference)
        return shortestDifference <= 20.0
    }
}
#endif
