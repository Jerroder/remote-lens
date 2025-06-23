//
//  LocationManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var locationDataReceived = false
    @Published var isLoading = false
    @Published var isLocationServiceEnabled = false
    
    @Published var isGeotagginEnabled: Bool = false
    @Published var showGPSDeniedAlert: Bool = false
    
    @Published var lastLocation: CLLocation?
    @Published var elevation: CLLocationDistance?
    
    private let locationManager = CLLocationManager()
    
    private var locationUpdateCompletion: ((CLLocationCoordinate2D?, CLLocationDistance?) -> Void)?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationUpdateCompletion?(nil, nil)
            return
        }
        
        locationUpdateCompletion?(location.coordinate, location.altitude)
        locationDataReceived = true
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        locationUpdateCompletion?(nil, nil)
    }
    
    func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    private func requestSingleLocationUpdate(completion: @escaping (CLLocationCoordinate2D?, CLLocationDistance?) -> Void) {
//        if isUpdatingLocation {
//            locationManager.stopUpdatingLocation()
//            isUpdatingLocation = false
//        }
        isLoading = true
        locationDataReceived = false
        locationUpdateCompletion = completion
        locationManager.requestLocation()
    }
    
    private func getCurrentUTCUnixEpochTimeAsData() -> Data {
        let currentDate = Date()
        let unixEpochTime = Int32(currentDate.timeIntervalSince1970)
        
        // Convert the Int32 to a Data object
        var timeValue = unixEpochTime
        let timeData = withUnsafeBytes(of: &timeValue) { Data($0) }
        
        return timeData
    }
    
    func updateLocationServiceStatus() {
        if locationStatus == .denied {
            isLocationServiceEnabled = false
        } else {
            isLocationServiceEnabled = true
        }
    }
    
    func getGPSData(completion: @escaping (Data) -> Void) {
        requestSingleLocationUpdate { coordinate, altitude in
            
            var data: Data = Data([0x04])
            if let coordinate = coordinate, let altitude = altitude {
                data.append(withUnsafeBytes(of: Float(coordinate.latitude)) { Data($0) })
                data.append(withUnsafeBytes(of: Float(coordinate.longitude)) { Data($0) })
                data.append(withUnsafeBytes(of: Float(altitude)) { Data($0) })
                
                if coordinate.latitude >= 0 {
                    data.insert(0x4E, at: 1)
                } else {
                    data.insert(0x53, at: 1)
                }
                
                if coordinate.longitude >= 0 {
                    data.insert(0x45, at: 6)
                } else {
                    data.insert(0x57, at: 6)
                }
                
                if altitude >= 0 {
                    data.insert(0x2B, at: 11)
                } else {
                    data.insert(0x2D, at: 11)
                }
            } else {
                if let status = self.locationStatus {
                    if status == .denied {
                        self.showGPSDeniedAlert = true
                        self.isLocationServiceEnabled = false
                    }
                }
                data.append(Data(count: 15))
            }
            
            let dateData: Data = self.getCurrentUTCUnixEpochTimeAsData()
            data.append(dateData)
            
            completion(data)
        }
    }
}
