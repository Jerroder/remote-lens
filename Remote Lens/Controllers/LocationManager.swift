//
//  LocationManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var elevation: CLLocationDistance?
    
    @Published var isGeotagginEnabled: Bool = false
    @Published var showGPSDeniedAlert: Bool = false
    
    private let locationManager = CLLocationManager()
    
    private var isUpdatingLocation = false
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        isUpdatingLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        elevation = location.altitude
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    private func requestSingleLocationUpdate() {
        if isUpdatingLocation {
            locationManager.stopUpdatingLocation()
            isUpdatingLocation = false
        }
        locationManager.requestLocation()
    }
    
    private func floatToData(_ value: Float) -> Data {
        var floatValue = value
        return withUnsafePointer(to: &floatValue) {
            Data(bytes: $0, count: MemoryLayout<Float>.size)
        }
    }
    
    private func getLocationAndElevation() -> (latitude: Data?, longitude: Data?, elevation: Data?) {
        guard let location = lastLocation else {
            print("Location data is not available.")
            return (nil, nil, nil)
        }
        
        let latitude = Float(location.coordinate.latitude)
        let longitude = Float(location.coordinate.longitude)
        let elevation = Float(location.altitude)
        
        var dataLatitude = floatToData(latitude)
        var dataLongitude = floatToData(longitude)
        var dataElevation = floatToData(elevation)
        
        if latitude >= 0 {
            dataLatitude.insert(0x4E, at: 0)
        } else {
            dataLatitude.insert(0x53, at: 0)
        }
        
        if longitude >= 0 {
            dataLongitude.insert(0x45, at: 0)
        } else {
            dataLongitude.insert(0x57, at: 0)
        }
        
        if elevation >= 0 {
            dataElevation.insert(0x2B, at: 0)
        } else {
            dataElevation.insert(0x2D, at: 0)
        }
        
        return (dataLatitude, dataLongitude, dataElevation)
    }
    
    private func getCurrentUTCUnixEpochTimeAsData() -> Data {
        let currentDate = Date()
        let unixEpochTime = Int32(currentDate.timeIntervalSince1970)
        
        // Convert the Int32 to a Data object
        var timeValue = unixEpochTime
        let timeData = withUnsafeBytes(of: &timeValue) { Data($0) }
        
        return timeData
    }
    
    func getGPSData() -> Data {
        requestSingleLocationUpdate()
        
        var data: Data = Data([0x04])
        if lastLocation != nil {
            let (dataLatitude, dataLongitude, dataElevation) = getLocationAndElevation()
            
            data.append(dataLatitude!)
            data.append(dataLongitude!)
            data.append(dataElevation!)
        } else {
            if let status = locationStatus {
                if status == .denied {
                    showGPSDeniedAlert = true
                }
            }
            data.append(Data(count: 15))
        }
        
        let dateData: Data = getCurrentUTCUnixEpochTimeAsData()
        data.append(dateData)
        
        return data
    }
}
