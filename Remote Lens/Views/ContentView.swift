//
//  ContentView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BluetoothManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var timerManager = TimerManager()
    
    @State private var selectedOption: Int = UserDefaults.standard.integer(forKey: "selectedOption")
    @State private var gpsInterval: Double = UserDefaults.standard.double(forKey: "gpsInterval")
    @State private var showGeotagSheet: Bool = false
    @State private var waitForFix: Bool = UserDefaults.standard.bool(forKey: "waitForFix")
    
    var body: some View {
        NavigationStack {
            if bleManager.isConnected {
                TabView {
                    NavigationStack {
                        OneShotView(bleManager: bleManager, locationManager: locationManager, showGeotagSheet: $showGeotagSheet, waitForFix: $waitForFix, selectedOption: $selectedOption)
                    }
                    .tabItem {
                        Label("one_shot".localized(comment: "One Shot"), systemImage: "camera")
                    }
                    
                    NavigationStack {
                        IntervalometerView(bleManager: bleManager, locationManager: locationManager, showGeotagSheet: $showGeotagSheet)
                    }
                    .tabItem {
                        Label("intervalometer".localized(comment: "Intervalometer"), systemImage: "timer")
                    }
                }
                .navigationTitle(bleManager.connectedPeripheral?.name ?? "unknown_device".localized(comment: "Unknown Device"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                bleManager.disconnect()
                            }) {
                                Label("disconnect".localized(comment: "Disconnect"), systemImage: "wifi.slash")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showGeotagSheet.toggle()
                            }) {
                                Label("geotagging".localized(comment: "Geotagging"), systemImage: "location")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showGeotagSheet) {
                    GeotaggingView(bleManager: bleManager, locationManager: locationManager, timerManager: timerManager,
                                   selectedOption: $selectedOption, gpsInterval: $gpsInterval, showGeotagSheet: $showGeotagSheet, waitForFix: $waitForFix)
                }
            } else {
                ConnectionView(bleManager: bleManager)
            }
        } /* NavigationStack */
        .overlay(
            Group {
                if bleManager.isConnecting {
                    VStack {
                        Text("connecting_please_wait".localized(comment: "Connecting, please wait..."))
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground).opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .alert("couldnt_connect_to_camera".localized(comment: "Couldn’t connect to the camera"), isPresented: Binding(
            get: { bleManager.warnRemoveFromiPhoneMenu },
            set: { newValue in bleManager.warnRemoveFromiPhoneMenu = newValue}
        )) {
            Button("close".localized(comment: "Close"), role: .cancel) { }
        } message: {
            Text("remove_from_iphone_menu_text".localized(comment: "Please remove the camera from your iPhone's list"))
        }
        .alert("couldnt_connect_to_camera".localized(comment: "Couldn’t connect to the camera"), isPresented: Binding(
            get: { bleManager.warnRemoveFromCameraMenu },
            set: { newValue in bleManager.warnRemoveFromCameraMenu = newValue }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("remove_from_camera_menu_text".localized(comment: "Please remove this iPhone from your camera’s list"))
        }
        .alert("lost_connection_to_camera".localized(comment: "Lost connection to the camera"), isPresented: Binding(
            get: { bleManager.warnCameraTurnedOff },
            set: { newValue in bleManager.warnCameraTurnedOff = newValue }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("camera_turned_off_text".localized(comment: "Please make sure the camera is turned on and in range."))
        }
        .alert("lost_connection_to_camera_unexpected".localized(comment: "Lost connection to the camera unexpectedly"), isPresented: Binding(
            get: { bleManager.warnCameraLostConnection },
            set: { newValue in bleManager.warnCameraLostConnection = newValue }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("lost_connection_to_camera_text".localized(comment: "Please make sure the camera is in range and its battery is charged."))
        }
        .alert("location_access_denied".localized(comment: "Location access denied"), isPresented: $locationManager.showGPSDeniedAlert) {
            Button("close".localized(comment: "Close"), role: .cancel) { }
            Button("settings".localized(comment: "Settings"), role: nil) { openSettings() }
        } message: {
            Text("location_access_denied_text".localized(comment: "Please enable location access in settings."))
        }
        .onAppear {
            if selectedOption == 2 {
                locationManager.isGeotagginEnabled = true
                locationManager.updateLocationServiceStatus()
                
                timerManager.startTimer(interval: gpsInterval) {
                    locationManager.getGPSData { data in
                        bleManager.writeGPSValue(data: data)
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
