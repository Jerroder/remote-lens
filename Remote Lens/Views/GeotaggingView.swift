//
//  GeotaggingView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import SwiftUI

struct NoGeotaggingView: View {
    @StateObject var bleManager: BluetoothManager
    @StateObject var locationManager: LocationManager
    @ObservedObject var timerManager: TimerManager
    @Binding var selectedOption: Int
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { withAnimation { selectedOption == 0 }},
            set: { newValue in
                withAnimation {
                    selectedOption = 0
                }
                
                UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                
                if newValue {
                    let data: Data = Data([0x03])
                    bleManager.writeGPSValue(data: data)
                    locationManager.isGeotagginEnabled = false
                    locationManager.setIsAsync(isAsync: false)
                    timerManager.stopTimer()
                }
            }
        )) {
            Text("no_geotagging".localized(comment: "No geotagging"))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct ManualGeotaggingView: View {
    @StateObject var bleManager: BluetoothManager
    @StateObject var locationManager: LocationManager
    @ObservedObject var timerManager: TimerManager
    @Binding var selectedOption: Int
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { withAnimation { selectedOption == 1 }},
            set: { newValue in
                withAnimation {
                    selectedOption = 1
                }
                
                UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                
                if newValue {
                    locationManager.isGeotagginEnabled = false
                    locationManager.locationDataReceived = false
                    locationManager.setIsAsync(isAsync: true)
                    timerManager.stopTimer()
                }
            }
        )) {
            Text("manual_geotagging".localized(comment: "Get GPS data manually"))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        
        if selectedOption == 1 {
            VStack(spacing: 10) {
                Text(!bleManager.isGPSEnabledOnCamera ? "gps_not_enabled".localized(comment: "GPS not enabled on camera, please enable or re-enable it") : "")
                
                Button(action: {
                    withAnimation {
                        locationManager.getGPSData { data in
                            bleManager.writeGPSValue(data: data)
                        }
                    }
                }) {
                    Text("send_gps_to_camera".localized(comment: "Send to camera"))
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                if !locationManager.isLocationServiceEnabled {
                    Text("location_access_denied".localized(comment: "Location access denied"))
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                } else if locationManager.isLoading {
                    Text("waiting_for_gps".localized(comment: "Waiting for GPS fix"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                } else if locationManager.locationDataReceived {
                    Text("gps_data_sent".localized(comment: "GPS data sent to the camera"))
                        .fontWeight(.regular)
                        .foregroundStyle(.green)
                }
            }
            .transition(.opacity)
        }
    }
}

struct GeotaggingOnceView: View {
    @StateObject var bleManager: BluetoothManager
    @StateObject var locationManager: LocationManager
    @ObservedObject var timerManager: TimerManager
    @Binding var selectedOption: Int
    @Binding var gpsInterval: Double
    
    @FocusState private var focusedField: Bool
    
    @State private var showingInfoAlert: Bool = false
    @State private var unit: Unit = Unit(symbol: "s")
    @State private var timer: Timer?
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { withAnimation { selectedOption == 2 }},
            set: { newValue in
                withAnimation {
                    selectedOption = 2
                }
                
                UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                
                if newValue {
                    locationManager.isGeotagginEnabled = true
                    locationManager.setIsAsync(isAsync: true)
                    
                    timerManager.startTimer(interval: gpsInterval) {
                        locationManager.getGPSData { data in
                            bleManager.writeGPSValue(data: data)
                        }
                    }
                }
            }
        )) {
            Text("geotagging_when_starting".localized(comment: "Get GPS coordinates once when the app starts"))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        
        if selectedOption == 2 {
            VStack(spacing: 10) {
                Text(!bleManager.isGPSEnabledOnCamera ? "gps_not_enabled".localized(comment: "GPS not enabled on camera, please enable or re-enable it") : "")
                
                HStack {
                    Text("gps_interval".localized(comment: "Get GPS data every"))
                    // .frame(width: 170, alignment: .leading)
                    TextFieldWithUnit(value: $gpsInterval, unit: $unit)
                        .keyboardType(.decimalPad)
                        .focused($focusedField)
                        .onChange(of: gpsInterval) { _, _ in
                            UserDefaults.standard.set(gpsInterval, forKey: "gpsInterval")
                            restartTimer()
                        }
                    
                    Spacer()
                    
                    Button(action: {
                        showingInfoAlert = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color(UIColor.systemGray))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .alert("Info", isPresented: $showingInfoAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("gps_interval_text".localized(comment: "If interval is 0"))
                    }
                }
                .padding(.horizontal)
                
                if !locationManager.isLocationServiceEnabled {
                    Text("location_access_denied".localized(comment: "Location access denied"))
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                } else if locationManager.isLoading {
                    Text("waiting_for_gps".localized(comment: "Waiting for GPS fix"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }
            .toolbar { // Throws an error for some reason, but it works
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focusedField = false
                    } label: {
                        Image(systemName: "checkmark")
                            .padding()
                    }
                }
            }
            .transition(.opacity)
        }
    }
    
    private func restartTimer() {
        timerManager.stopTimer()
        timerManager.startTimer(interval: gpsInterval) {
            locationManager.getGPSData { data in
                bleManager.writeGPSValue(data: data)
            }
        }
    }
}

struct GeotaggingWhenTriggeredView: View {
    @StateObject var bleManager: BluetoothManager
    @StateObject var locationManager: LocationManager
    @ObservedObject var timerManager: TimerManager
    @Binding var selectedOption: Int
    @Binding var waitForFix: Bool
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { withAnimation { selectedOption == 3 }},
            set: { newValue in
                withAnimation {
                    selectedOption = 3
                }
                
                UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                
                if newValue {
                    locationManager.isGeotagginEnabled = true
                    timerManager.stopTimer()
                }
            }
        )) {
            Text("geotagging_when_triggering".localized(comment: "Get GPS coordinates every time a photo is taken"))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        
        if selectedOption == 3 {
            VStack(spacing: 10) {
                Toggle("wait_for_gps".localized(comment: "Wait for GPS to get a fix before taking the photo"), isOn: $waitForFix)
                    .padding()
                    .onChange(of: waitForFix) { _, newValue in
                        UserDefaults.standard.set(waitForFix, forKey: "waitForFix")
                        locationManager.setIsAsync(isAsync: newValue)
                    }
            }
            .transition(.opacity)
        }
    }
}

struct GeotaggingView: View {
    @StateObject var bleManager: BluetoothManager
    @StateObject var locationManager: LocationManager
    @StateObject var timerManager: TimerManager
    @Binding var selectedOption: Int
    @Binding var gpsInterval: Double
    @Binding var showGeotagSheet: Bool
    @Binding var waitForFix: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("select_an_option".localized(comment: "Select an Option"))
                    .font(.headline)
                    .padding()
                
                NoGeotaggingView(bleManager: bleManager, locationManager: locationManager, timerManager: timerManager, selectedOption: $selectedOption)
                
                ManualGeotaggingView(bleManager: bleManager, locationManager: locationManager, timerManager: timerManager, selectedOption: $selectedOption)
                
                GeotaggingOnceView(bleManager: bleManager, locationManager: locationManager, timerManager: timerManager, selectedOption: $selectedOption, gpsInterval: $gpsInterval)
                
                GeotaggingWhenTriggeredView(bleManager: bleManager, locationManager: locationManager, timerManager: timerManager, selectedOption: $selectedOption, waitForFix: $waitForFix)
                
                Spacer()
            } /* VStack */
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done".localized(comment: "Done"), systemImage: "checkmark") {
                        showGeotagSheet = false
                    }
                }
            }
        } /* NavigationStack */
        .onAppear{
            locationManager.updateLocationServiceStatus()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
