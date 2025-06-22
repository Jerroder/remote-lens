//
//  GeotaggingView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import SwiftUI

struct GeotaggingView: View {
    @StateObject var bleManager: BluetoothManager
    @StateObject var locationManager: LocationManager
    @Binding var selectedOption: Int
    @Binding var showGeotagSheet: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("select_an_option".localized(comment: "Select an Option"))
                    .font(.headline)
                    .padding()
                
                /* No geotagging */
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
                        }
                    }
                )) {
                    Text("no_geotagging".localized(comment: "No geotagging"))
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                /* Get GPS data manually */
                Toggle(isOn: Binding(
                    get: { withAnimation { selectedOption == 1 }},
                    set: { newValue in
                        withAnimation {
                            selectedOption = 1
                        }
                        
                        UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                        
                        if newValue {
                            locationManager.isGeotagginEnabled = false
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
                            locationManager.getGPSData { data in
                                bleManager.writeGPSValue(data: data)
                            }
                        }) {
                            Text("send_gps_to_camera".localized(comment: "Send to camera"))
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        
                        Text(locationManager.isLoading ? "no_gps_data".localized(comment: "No GPS data") : "")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    .transition(.opacity)
                }
                
                /* Get GPS data once */
                Toggle(isOn: Binding(
                    get: { withAnimation { selectedOption == 2 }},
                    set: { newValue in
                        withAnimation {
                            selectedOption = 2
                        }
                        
                        UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                        
                        if newValue {
                            locationManager.isGeotagginEnabled = true
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
                        Toggle("Interval", isOn: Binding(
                            get: { false }, // Replace with your logic for sub-options
                            set: { _ in /* Handle sub-option selection */ }
                        ))
                    }
                    .transition(.opacity)
                }
                
                /* Get GPS data for every photo */
                Toggle(isOn: Binding(
                    get: { withAnimation { selectedOption == 3 }},
                    set: { newValue in
                        withAnimation {
                            selectedOption = 3
                        }
                        
                        UserDefaults.standard.set(selectedOption, forKey: "selectedOption")
                        
                        if newValue {
                            locationManager.isGeotagginEnabled = true
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
                        Toggle("Wait for GPS to get a fix before taking the photo", isOn: Binding(
                            get: { false }, // Replace with your logic for sub-options
                            set: { _ in /* Handle sub-option selection */ }
                        ))
                    }
                    .transition(.opacity)
                }
                
                Spacer()
            } /* VStack */
            .padding()
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        showGeotagSheet = false
                    }) {
                        Text("done".localized(comment: "Done"))
                    }
                }
            }
            .alert(isPresented: $locationManager.showGPSDeniedAlert) {
                Alert(
                    title: Text("location_access_denied".localized(comment: "Location access denied")),
                    message: Text("location_access_denied_text".localized(comment: "Please enable location access in settings.")),
                    primaryButton: .default(Text("settings".localized(comment: "Settings"))) {
                        openSettings()
                    },
                    secondaryButton: .default(Text("close".localized(comment: "Close")))
                )
            }
        } /* NavigationStack */
        .onAppear{
            bleManager.queryCameraForGPSStatus()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
