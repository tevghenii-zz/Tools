//    Copyright (c) 2017 Evghenii Todorov
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import UIKit
import CoreLocation

class Location: NSObject {
    static let GeocodeCompletedNotification     = Notification.Name(rawValue: "GeocodeCompletedNotification")
    static let UnauthorizedAccessNotification   = Notification.Name(rawValue: "UnauthorizedAccessNotification")
    static let LocationUpdatedNotification      = Notification.Name(rawValue: "LocationUpdatedNotification")
    
    fileprivate var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentPlace: CLPlacemark?
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
        locationManager.delegate = self
    }
    
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func geocode(location: CLLocation? = nil) {
        let location = location ?? currentLocation
        guard let geocodeLocation = location else { return }

        CLGeocoder().reverseGeocodeLocation(geocodeLocation) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                guard let sself = self else { return }
                
                sself.currentPlace = placemark
                
                let userInfo: [String: Any] = [ "LocationManager": sself, "Place": placemark ]
                NotificationCenter.default.post(name: Location.GeocodeCompletedNotification, object: nil, userInfo: userInfo)
            }
        }
    }
}

extension Location: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Location Authorization status is not determined")
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied:
            NotificationCenter.default.post(name: Location.UnauthorizedAccessNotification, object: nil)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let eventDate = location.timestamp
        let howRecent = eventDate.timeIntervalSinceNow
        
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 100 {
            return
        }
        
        if abs(howRecent) > 30.0 {
            return
        }
        
        currentLocation = location
        
        let userInfo: [String: Any] = [ "LocationManager": self, "Location": location ]
        NotificationCenter.default.post(name: Location.LocationUpdatedNotification, object: nil, userInfo: userInfo)
    }
}
