//
//  MockBluetoothManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-10-31.
//

import Combine
import Foundation
import UIKit

class MockBluetoothManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isBluetoothEnabled: Bool = true
    @Published var peripherals: [MockPeripheral] = [
        MockPeripheral(name: "EOSR6", identifier: UUID())
    ]
    @Published var connectedPeripheral: MockPeripheral?
    @Published var isShootingMode: Bool = true
    @Published var isRecording: Bool = false
    @Published var hasAutofocusFailed: Bool = false
    @Published var requiresPairing: Bool = false
    @Published var showPairingAlert: Bool = false
    @Published var selectedPeripheral: MockPeripheral?
    @Published var warnRemoveFromiPhoneMenu: Bool = false
    @Published var warnRemoveFromCameraMenu: Bool = false
    @Published var warnCameraTurnedOff: Bool = false
    @Published var warnCameraLostConnection: Bool = false
    @Published var isGPSEnabledOnCamera: Bool = true
    
    var iphoneName: String = UIDevice.current.name
    
    func connect(to peripheral: MockPeripheral) {
        isConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isConnecting = false
            self.isConnected = true
            self.connectedPeripheral = peripheral
        }
    }
    
    func disconnect() {
        isConnected = false
        connectedPeripheral = nil
    }
    
    func requestConnection(to peripheral: MockPeripheral) {
        selectedPeripheral = peripheral
        showPairingAlert = true
    }
    
    func userDidConfirmConnection() {
        showPairingAlert = false
        connect(to: selectedPeripheral!)
    }
    
    func userDidCancelConnection() {
        showPairingAlert = false
        selectedPeripheral = nil
    }
    
    func takePhoto() {
        print("Mock: Taking photo")
    }
    
    func pressShutter() {
        print("Mock: Shutter pressed")
    }
    
    func releaseShutter() {
        print("Mock: Shutter released")
    }
    
    func startRecording() {
        isRecording = true
        print("Mock: Recording started")
    }
    
    func stopRecording() {
        isRecording = false
        print("Mock: Recording stopped")
    }
    
    func switchMode() {
        isShootingMode.toggle()
        print("Mock: Mode switched to \(isShootingMode ? "Shooting" : "Playback")")
    }
    
    func pressNavigationButton(button: Buttons) {
        print("Mock: \(button) button pressed")
    }
    
    func writeGPSValue(data: Data?) {
        print("Mock: GPS value written")
    }
}

struct MockPeripheral: Identifiable {
    let id: UUID
    let name: String?
    let identifier: UUID
    
    init(name: String?, identifier: UUID) {
        self.id = identifier
        self.name = name
        self.identifier = identifier
    }
}
