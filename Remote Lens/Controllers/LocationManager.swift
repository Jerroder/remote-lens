//
//  LocationManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var _locationStatus: CLAuthorizationStatus?
    @Published var _locationDataReceived = false
    @Published var _isLoading = false
    @Published var _isLocationServiceEnabled = false
    
    @Published var _isGeotagginEnabled: Bool = false
    @Published var _showGPSDeniedAlert: Bool = false
    
    @Published var _lastLocation: CLLocation?
    @Published var _elevation: CLLocationDistance?
    
    private let locationManager = CLLocationManager()
    
    private var locationUpdateCompletion: ((CLLocationCoordinate2D?, CLLocationDistance?) -> Void)?
    private var isAsync: Bool = false
    
    var locationStatus: CLAuthorizationStatus? {
        get {
            return _locationStatus
        }
    }
    
    var locationDataReceived: Bool {
        get {
            return _locationDataReceived
        }
        set {
            _locationDataReceived = newValue
        }
    }
    
    var isLoading: Bool {
        get {
            return _isLoading
        }
    }
    
    var isLocationServiceEnabled: Bool {
        get {
            return _isLocationServiceEnabled
        }
    }
    
    var isGeotagginEnabled: Bool {
        get {
            return _isGeotagginEnabled
        }
        set {
            _isGeotagginEnabled = newValue
        }
    }
    
    var showGPSDeniedAlert: Bool {
        get {
            return _showGPSDeniedAlert
        }
        set {
            _showGPSDeniedAlert = newValue
        }
    }
    
    var lastLocation: CLLocation? {
        get {
            return _lastLocation
        }
    }
    
    var elevation: CLLocationDistance? {
        get {
            return _elevation
        }
    }
    
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
        
        if isAsync {
            locationUpdateCompletion?(location.coordinate, location.altitude)
        }
        _locationDataReceived = true
        _isLoading = false
        
        _lastLocation = location
        _elevation = location.altitude
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        _locationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        locationUpdateCompletion?(nil, nil)
    }
    
    func setIsAsync(isAsync: Bool) {
        self.isAsync = isAsync
    }
    
    func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    private func requestSingleLocationUpdate() {
        _isLoading = true
        _locationDataReceived = false
        locationManager.requestLocation()
    }
    
    private func requestSingleLocationUpdate(completion: @escaping (CLLocationCoordinate2D?, CLLocationDistance?) -> Void) {
        _isLoading = true
        _locationDataReceived = false
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
        if _locationStatus == .denied {
            _isLocationServiceEnabled = false
        } else {
            _isLocationServiceEnabled = true
        }
    }
    
    private func floatToData(_ value: Float) -> Data {
        var floatValue = value
        return withUnsafePointer(to: &floatValue) {
            Data(bytes: $0, count: MemoryLayout<Float>.size)
        }
    }

    private func getLocationAndElevation() -> (latitude: Data?, longitude: Data?, _elevation: Data?) {
        guard let location = _lastLocation else {
            print("Location data is not available.")
            return (nil, nil, nil)
        }

        let latitude = Float(location.coordinate.latitude)
        let longitude = Float(location.coordinate.longitude)
        let _elevation = Float(location.altitude)

        var dataLatitude = floatToData(latitude)
        var dataLongitude = floatToData(longitude)
        var dataElevation = floatToData(_elevation)

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

        if _elevation >= 0 {
            dataElevation.insert(0x2B, at: 0)
        } else {
            dataElevation.insert(0x2D, at: 0)
        }

        return (dataLatitude, dataLongitude, dataElevation)
    }
    
    func getGPSData() -> Data {
        requestSingleLocationUpdate()
        
        var data: Data = Data([0x04])
        if _lastLocation != nil {
            let (dataLatitude, dataLongitude, dataElevation) = getLocationAndElevation()
            
            data.append(dataLatitude!)
            data.append(dataLongitude!)
            data.append(dataElevation!)
        } else {
            if let status = _locationStatus {
                if status == .denied {
                    _showGPSDeniedAlert = true
                }
            }
            
            data.append(Data(count: 12))
            data.insert(0x4E, at: 1)
            data.insert(0x45, at: 6)
            data.insert(0x2B, at: 11)
        }
        
        let dateData: Data = getCurrentUTCUnixEpochTimeAsData()
        data.append(dateData)
        
        return data
    }
    
    func getGPSData(completion: @escaping (Data) -> Void) {
        requestSingleLocationUpdate { coordinate, altitude in
            
            var data: Data = Data([0x04])
            if let coordinate = coordinate, let altitude = altitude {
                data.append(withUnsafeBytes(of: Float(coordinate.latitude)) { Data($0) })
                data.append(withUnsafeBytes(of: Float(coordinate.longitude)) { Data($0) })
                data.append(withUnsafeBytes(of: Float(altitude)) { Data($0) })
                
                if coordinate.latitude >= 0 {
                    data.insert(0x4E, at: 1) // ASCII for 'N'
                } else {
                    data.insert(0x53, at: 1) // ASCII for 'S'
                }
                
                if coordinate.longitude >= 0 {
                    data.insert(0x45, at: 6) // ASCII for 'E'
                } else {
                    data.insert(0x57, at: 6) // ASCII for 'W'
                }
                
                if altitude >= 0 {
                    data.insert(0x2B, at: 11) // ASCII for '+'
                } else {
                    data.insert(0x2D, at: 11) // ASCII for '-'
                }
            } else {
                if let status = self._locationStatus {
                    if status == .denied {
                        self._showGPSDeniedAlert = true
                        self._isLocationServiceEnabled = false
                    }
                }
                data.append(Data(count: 15))
                data.insert(0x4E, at: 1)
                data.insert(0x45, at: 6)
                data.insert(0x2B, at: 11)
            }
            
            let dateData: Data = self.getCurrentUTCUnixEpochTimeAsData()
            data.append(dateData)
            
            completion(data)
        }
    }
}
