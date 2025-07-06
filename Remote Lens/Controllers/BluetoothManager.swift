//
//  BluetoothManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-11.
//

import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    enum Buttons {
        case middle
        case right
        case left
        case up
        case down
        case back
        case zoomIn
        case zoomOut
    }
    
    @Published private var _peripherals: [CBPeripheral] = [CBPeripheral]()
    @Published private var _connectedPeripheral: CBPeripheral?
    @Published private var _isConnected: Bool = false
    @Published private var _isBluetoothEnabled: Bool = false
    @Published private var _isShootingMode: Bool = true
    @Published private var _isRecording: Bool = false
    @Published private var _hasAutofocusFailed: Bool = false
    @Published private var _isGPSEnabledOnCamera: Bool = false
    @Published private var _warnRemoveFromCameraMenu: Bool = false
    @Published private var _warnRemoveFromiPhoneMenu: Bool = false
    @Published private var _warnCameraTurnedOff: Bool = false
    @Published private var _isConnecting: Bool = false
    
    private let handshakeService: CBUUID = CBUUID(string: "00010000-0000-1000-0000-D8492FffA821")
    private let checkPairingUUID: CBUUID = CBUUID(string: "00010005-0000-1000-0000-D8492FFFA821")
    private let endHandshakeUUID: CBUUID = CBUUID(string: "0001000a-0000-1000-0000-D8492FffA821")
    private let startHandshakeUUID: CBUUID = CBUUID(string: "00010006-0000-1000-0000-D8492FffA821")
    
    private let operationService: CBUUID = CBUUID(string: "00030000-0000-1000-0000-d8492fffa821")
    private let modeChangeUUID: CBUUID = CBUUID(string: "00030010-0000-1000-0000-d8492fffa821")
    private let modeNotifyUUID: CBUUID = CBUUID(string: "00030011-0000-1000-0000-d8492fffa821")
    private let playbackNavigationUUID: CBUUID = CBUUID(string: "00030020-0000-1000-0000-d8492fffa821")
    private let actuateShutterUUID: CBUUID = CBUUID(string: "00030030-0000-1000-0000-D8492FffA821")
    private let autofocusNotifiyUUID: CBUUID = CBUUID(string: "00030031-0000-1000-0000-d8492fffa821")
    
    private let geotagService: CBUUID = CBUUID(string: "00040000-0000-1000-0000-D8492FFFA821")
    private let geotagDataUUID: CBUUID = CBUUID(string: "00040002-0000-1000-0000-D8492FFFA821")
    private let confirmGeotagUUID: CBUUID = CBUUID(string: "00040003-0000-1000-0000-D8492FFFA821")
    
    private let canonCompanyIdentifier: UInt16 = 0x01A9
    
    private var discoveredPeripheralIDs: Set<UUID> = Set<UUID>()
    private var centralManager: CBCentralManager!
    
    private var endHandshakeCharacteristic: CBCharacteristic?
    private var confirmHandshakeCharacteristic: CBCharacteristic?
    private var shutterCharacteristic: CBCharacteristic?
    private var modeChangeCharacteristic: CBCharacteristic?
    private var modeNotifyCharacteristic: CBCharacteristic?
    private var playbackNavigationCharacteristic: CBCharacteristic?
    private var autofocusNavigationCharacteristic: CBCharacteristic?
    private var geotagDataCharacteristic: CBCharacteristic?
    private var confirmGeotagCharacteristic: CBCharacteristic?
    private var checkPairingCharacteristic: CBCharacteristic?
    
    private var scanTimer: Timer?
    private var shouldScan: Bool = true
    private var lastConnectedPeripheralUUID: UUID?
    private var hasUserInitiatedDisconnect: Bool = false
    private var isReconnecting: Bool = false
    private var requiresPairing: Bool = true
    private var isAutofocusSuccess: Bool = false
    
    var peripherals: [CBPeripheral] {
        get {
            return _peripherals
        }
    }
    
    var connectedPeripheral: CBPeripheral? {
        get {
            return _connectedPeripheral
        }
    }
    
    var isConnected: Bool {
        get {
            return _isConnected
        }
    }
    
    var isBluetoothEnabled: Bool {
        get {
            return _isBluetoothEnabled
        }
    }
    
    var isShootingMode: Bool {
        get {
            return _isShootingMode
        }
    }
    
    var isRecording: Bool {
        get {
            return _isRecording
        }
    }
    
    var hasAutofocusFailed: Bool {
        get {
            return _hasAutofocusFailed
        }
    }
    
    var isGPSEnabledOnCamera: Bool {
        get {
            return _isGPSEnabledOnCamera
        }
    }
    
    var warnRemoveFromCameraMenu: Bool {
        get {
            return _warnRemoveFromCameraMenu
        }
        set {
            _warnRemoveFromCameraMenu = newValue
        }
    }
    
    var warnRemoveFromiPhoneMenu: Bool {
        get {
            return _warnRemoveFromiPhoneMenu
        }
        set {
            _warnRemoveFromiPhoneMenu = newValue
        }
    }
    
    var warnCameraTurnedOff: Bool {
        get {
            return _warnCameraTurnedOff
        }
        set {
            _warnCameraTurnedOff = newValue
        }
    }
    
    var isConnecting: Bool {
        get {
            return _isConnecting
        }
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        if let uuidString = UserDefaults.standard.string(forKey: "lastConnectedPeripheralUUID") {
            lastConnectedPeripheralUUID = UUID(uuidString: uuidString)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            _isBluetoothEnabled = true
            startScanningCycle()
        } else {
            _isBluetoothEnabled = false
            print("Bluetooth is not available.")
        }
    }
    
    private func startScanningCycle() {
        guard shouldScan else {
            print("Scanning is disabled.")
            return
        }
        
        scanTimer?.invalidate()
        
        DispatchQueue.main.async {
            self._peripherals.removeAll()
            self.discoveredPeripheralIDs.removeAll()
        }
        
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.centralManager.stopScan()
            
            self?.scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.startScanningCycle()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count >= 2 {
                let companyIdentifier = manufacturerData.subdata(in: 0..<2).withUnsafeBytes { $0.load(as: UInt16.self) }
                if companyIdentifier == canonCompanyIdentifier {
                    if advertisementData[CBAdvertisementDataLocalNameKey] != nil { // the Camera advertises 2 devices, only one has the key CBAdvertisementDataLocalNameKey
                        discoveredPeripheralIDs.insert(peripheral.identifier)
                        DispatchQueue.main.async {
                            self._peripherals.append(peripheral)
                        }
                        
                        if peripheral.identifier == lastConnectedPeripheralUUID && !hasUserInitiatedDisconnect {
                            connect(to: peripheral)
                        }
                    }
                    
                    return
                }
            }
        }
        
        print("Discovered non-Canon peripheral: \(peripheral.name ?? "Unknown")")
    }
    
    func connect(to peripheral: CBPeripheral) {
        shouldScan = false
        
        centralManager.stopScan()
        
        scanTimer?.invalidate()
        scanTimer = nil
        
        isReconnecting = (peripheral.identifier == lastConnectedPeripheralUUID) && lastConnectedPeripheralUUID != nil
        
        DispatchQueue.main.async {
            self._isConnecting = true
        }
        
        centralManager.connect(peripheral, options: nil)
        _connectedPeripheral = peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self._isConnected = true
        }
        
        peripheral.delegate = self
        
        let serviceUUIDs = [
            handshakeService,
            operationService,
            geotagService
        ]
        
        lastConnectedPeripheralUUID = peripheral.identifier
        peripheral.discoverServices(serviceUUIDs)
        _connectedPeripheral?.delegate = self
        
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: "lastConnectedPeripheralUUID")
        hasUserInitiatedDisconnect = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        print("Found service \(service.uuid)")
        for characteristic in characteristics {
            switch characteristic.uuid {
            case startHandshakeUUID:
                print("Found characteristic for camera confirmation")
                let handshakeData = Data([0x01] + "iPhone 11 Pro".utf8)
                peripheral.writeValue(handshakeData, for: characteristic, type: .withResponse)
                
                confirmHandshakeCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: confirmHandshakeCharacteristic!)
                
            case endHandshakeUUID:
                print("Found characteristic for handshake")
                endHandshakeCharacteristic = characteristic
                
            case actuateShutterUUID:
                print("Found characteristic for shutter")
                shutterCharacteristic = characteristic
                
            case modeChangeUUID:
                print("Found characteristic for mode change")
                modeChangeCharacteristic = characteristic
                
            case modeNotifyUUID:
                print("Found characteristic for mode change notification")
                modeNotifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: modeNotifyCharacteristic!)
                
            case playbackNavigationUUID:
                print("Found characteristic for playback navigation")
                playbackNavigationCharacteristic = characteristic
                
            case autofocusNotifiyUUID:
                print("Found characteristic for autofocus notification")
                autofocusNavigationCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: autofocusNavigationCharacteristic!)
                
            case geotagDataUUID:
                print("Found characteristic for geotagging data")
                geotagDataCharacteristic = characteristic
                
            case confirmGeotagUUID:
                print("Found characteristic to confirm geotagging capabilities")
                confirmGeotagCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                // Putting this here because this is the last discovered characteristic
                // let's hope all R series camera can be paired with a GPS receiver
                peripheral.readValue(for: checkPairingCharacteristic!)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !self.requiresPairing {
                        let finishHandshakeData = Data([0x01])
                        peripheral.writeValue(finishHandshakeData, for: self.endHandshakeCharacteristic!, type: .withResponse)
                        self.isReconnecting = false
                        DispatchQueue.main.async {
                            self._isConnecting = false
                        }
                        
                        let wakeCamera = Data([0x03]) // Needed so that the camera notifies when recording starts
                        peripheral.writeValue(wakeCamera, for: self.modeChangeCharacteristic!, type: .withResponse)
                    }
                }
                
            case checkPairingUUID:
                print("Found characteristic to check pairing")
                checkPairingCharacteristic = characteristic
                
            default:
                print("Found characteristic \(characteristic.uuid)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueForCharacteristic \(characteristic.uuid)")
        
        if characteristic.uuid == confirmHandshakeCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x02]) {
                    print("User pressed OK. Ready to perform handshake.")
                    peripheral.setNotifyValue(false, for: characteristic)
                    performHandshake(with: peripheral)
                } else if value == Data([0x03]) {
                    print("User pressed Cancel.")
                    centralManager.cancelPeripheralConnection(peripheral)
                } else {
                    let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                    print("Value not recognized for confirmHandshakeCharacteristic: \(hexString)")
                }
            }
        } else if characteristic.uuid == modeNotifyCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x04]) {
                    _isShootingMode = true
                } else if value == Data([0x03]) {
                    _isShootingMode = false
                } else if value == Data([0x01]) {
                    _isShootingMode = true
                } else {
                    let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                    print("Value not recognized for modeNotifyCharacteristic: \(hexString)")
                }
            }
        } else if characteristic.uuid == autofocusNavigationCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x01, 0x01, 0x01]) && isRecording {
                    _isRecording = false
                } else if value == Data([0x01, 0x01, 0x01]) && !isRecording {
                    if !isAutofocusSuccess {
                        _hasAutofocusFailed = true
                    }
                } else if value == Data([0x01, 0x02, 0x01]) {
                    _hasAutofocusFailed = false
                    isAutofocusSuccess = true
                } else if value == Data([0x01, 0x01, 0x02]) {
                    _isRecording = true
                } else {
                    let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                    print("Value not recognized for autofocusNavigationCharacteristic: \(hexString)")
                }
            }
        } else if characteristic.uuid == confirmGeotagCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x03]) {
                    let confirmGeotagData = Data([0x01])
                    _connectedPeripheral?.writeValue(confirmGeotagData, for: geotagDataCharacteristic!, type: .withResponse)
                } else if value == Data([0x02]) {
                    _isGPSEnabledOnCamera = true
                } else if value == Data([0x01]) {
                    _isGPSEnabledOnCamera = false
                } else {
                    let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                    print("Value not recognized for confirmGeotagCharacteristic: \(hexString)")
                }
            }
        } else if characteristic.uuid == checkPairingCharacteristic?.uuid {
            if let value = characteristic.value {
                if value == Data([0x01]) {
                    requiresPairing = false
                } else {
                    let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                    print("Value not recognized for checkPairingCharacteristic: \(hexString)")
                }
            }
        } else {
            if let value = characteristic.value {
                let hexString = value.map { String(format: "%02hhx", $0) }.joined()
                print("Value not recognized for unknown characteristic: \(characteristic.uuid) \(hexString)")
            } else {
                print("no value")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        
        if let error = error as? CBError {
            if error.code == CBError.peripheralDisconnected {
                if requiresPairing { // Happens when the camera is deleted from the iPhone's known devices list
                    _warnRemoveFromCameraMenu = true
                    
                    lastConnectedPeripheralUUID = nil
                    UserDefaults.standard.removeObject(forKey: "lastConnectedPeripheralUUID")
                    
                    DispatchQueue.main.async {
                        self._isConnecting = false
                    }
                } else { // Happens when the camera is simply turned off
                    _warnCameraTurnedOff = true
                }
            } else if error.code == CBError.connectionTimeout {
                print("The connection has timed out unexpectedly")
            } else {
                print("Disconnected with error: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            self._isConnected = false
        }
        
        shouldScan = true
        startScanningCycle()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "Unknown")")
        
        // Happens when the iPhone is deleted from the camera's known devices list
        if let error = error as? CBError, error.code == CBError.peerRemovedPairingInformation {
            _warnRemoveFromiPhoneMenu = true
            
            lastConnectedPeripheralUUID = nil
            UserDefaults.standard.removeObject(forKey: "lastConnectedPeripheralUUID")
            
            DispatchQueue.main.async {
                self._isConnecting = false
            }
        }
        
        shouldScan = true
        startScanningCycle()
    }
    
    func writeGPSValue(data: Data) {
        guard let geotagDataCharacteristic = geotagDataCharacteristic else {
            print("Geotagging characteristic not found or not enabled on camera")
            return
        }
        
        _connectedPeripheral?.writeValue(data, for: geotagDataCharacteristic, type: .withResponse)
    }
    
    private func performHandshake(with peripheral: CBPeripheral) {
        guard let characteristic = endHandshakeCharacteristic else {
            print("Handshake characteristic not found.")
            return
        }
        
        print("Performing handshake...")
        
        // Write device ID (16 random bytes)
        let deviceID = (0..<16).map { _ in UInt8.random(in: 0...255) }
        print("device ID: \(deviceID)")
        let deviceIDData = Data([0x03] + deviceID)
        peripheral.writeValue(deviceIDData, for: characteristic, type: .withResponse)
        
        // Write device name
        let deviceNameData = Data([0x04] + "iPhone 11 Pro".utf8) // @TODO: replace with prompted name
        peripheral.writeValue(deviceNameData, for: characteristic, type: .withResponse)
        
        // Write device type (e.g., iOS)
        let deviceTypeData = Data([0x05, 0x01]) // 0x01 for iOS
        peripheral.writeValue(deviceTypeData, for: characteristic, type: .withResponse)
        
        // Finish handshake
        let finishHandshakeData = Data([0x01])
        peripheral.writeValue(finishHandshakeData, for: characteristic, type: .withResponse)
        
        DispatchQueue.main.async {
            self._isConnecting = false
        }
    }
    
    func pressShutter() {
        guard let shutterCharacteristic = shutterCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }
        
        isAutofocusSuccess = false
        _hasAutofocusFailed = false
        
        let pressData = Data([0x00, 0x01])
        _connectedPeripheral?.writeValue(pressData, for: shutterCharacteristic, type: .withResponse)
    }
    
    func releaseShutter() {
        guard let shutterCharacteristic = shutterCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }
        
        let releaseData = Data([0x00, 0x02])
        _connectedPeripheral?.writeValue(releaseData, for: shutterCharacteristic, type: .withResponse)
    }
    
    func takePhoto() {
        pressShutter()
        releaseShutter()
    }
    
    func startRecording() {
        guard let shutterCharacteristic = shutterCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }
        
        _hasAutofocusFailed = false
        
         let pressData = Data([0x00, 0x10])
         _connectedPeripheral?.writeValue(pressData, for: shutterCharacteristic, type: .withResponse)
    }
    
    func stopRecording() {
        guard let shutterCharacteristic = shutterCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }
        
         let releaseData = Data([0x00, 0x11])
         _connectedPeripheral?.writeValue(releaseData, for: shutterCharacteristic, type: .withResponse)
    }
    
    private func switchToPlayback() {
        guard let modeChangeCharacteristic = modeChangeCharacteristic else {
            print("Mode change characteristic not found.")
            return
        }
        
        let playbackData = Data([0x01])
        _connectedPeripheral?.writeValue(playbackData, for: modeChangeCharacteristic, type: .withResponse)
    }
    
    private func switchToShooting() {
        guard let modeChangeCharacteristic = modeChangeCharacteristic else {
            print("Mode change characteristic not found.")
            return
        }
        
        let shootingData = Data([0x02])
        _connectedPeripheral?.writeValue(shootingData, for: modeChangeCharacteristic, type: .withResponse)
    }
    
    func switchMode() {
        if _isShootingMode {
            switchToPlayback()
        } else {
            switchToShooting()
        }
    }
    
    func disconnect() {
        guard let peripheral = _connectedPeripheral else {
            print("No connected peripheral to disconnect from.")
            return
        }
        
        hasUserInitiatedDisconnect = true
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func pressNavigationButton(button: Buttons) {
        guard let playbackNavigationCharacteristic = playbackNavigationCharacteristic else {
            print("Shutter characteristic not found.")
            return
        }
        
        var pressButtonData: Data
        var releaseButtonData: Data
        switch button {
        case .middle:
            pressButtonData = Data([0x10, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x10, 0x00, 0x00, 0x40])
        case .right:
            pressButtonData = Data([0x08, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x08, 0x00, 0x00, 0x40])
        case .left:
            pressButtonData = Data([0x04, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x04, 0x00, 0x00, 0x40])
        case .up:
            pressButtonData = Data([0x01, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x01, 0x00, 0x00, 0x40])
        case .down:
            pressButtonData = Data([0x02, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x02, 0x00, 0x00, 0x40])
        case .back:
            pressButtonData = Data([0x20, 0x00, 0x00, 0xc0])
            releaseButtonData = Data([0x20, 0x00, 0x00, 0x40])
        case .zoomIn:
            pressButtonData = Data([0x40, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x40, 0x00, 0x00, 0x40])
        case .zoomOut:
            pressButtonData = Data([0x80, 0x00, 0x00, 0x80])
            releaseButtonData = Data([0x80, 0x00, 0x00, 0x40])
        }
        
        _connectedPeripheral?.writeValue(pressButtonData, for: playbackNavigationCharacteristic, type: .withResponse)
        _connectedPeripheral?.writeValue(releaseButtonData, for: playbackNavigationCharacteristic, type: .withResponse)
    }
}
