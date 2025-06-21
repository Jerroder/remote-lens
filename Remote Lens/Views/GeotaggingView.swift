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
    @Binding var selectedOption: Int8
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
                        
                        if newValue {
                            bleManager.isGeotagginEnabled = false
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
                        
                        if newValue {
                            bleManager.isGeotagginEnabled = false
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
                        Text(!bleManager.isGeotagginCapable ? "gps_not_enabled".localized(comment: "GPS not enabled on camera, please enable or re-enable it") : "")
                        
                        Button(action: {
                            bleManager.writeGPSValue(data: locationManager.getGPSData())
                        }) {
                            Text("send_gps_to_camera".localized(comment: "Send to camera"))
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        
                        Text((locationManager.lastLocation == nil) ? "no_gps_data".localized(comment: "No GPS data") : "")
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
                        
                        if newValue {
                            bleManager.isGeotagginEnabled = true
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
                        
                        if newValue {
                            bleManager.isGeotagginEnabled = true
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
        } /* NavigationStack */
    }
}
