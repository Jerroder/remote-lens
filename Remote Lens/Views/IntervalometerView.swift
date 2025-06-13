//
//  IntervalometerView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-13.
//

import SwiftUI

struct IntervalometerView: View {
    private enum Field: Int, CaseIterable {
        case numberOfPhotos, waitBetweenPhotos, exposureTime
    }

    @ObservedObject var bleManager: BluetoothManager

    @State private var numberOfPhotos: Int
    @State private var waitBetweenPhotos: Double
    @State private var exposureTime: Double
    @State private var isRunning: Bool = false
    
    @FocusState private var focusedField: Field?

    private let numberOfPhotosKey = "numberOfPhotos"
    private let waitBetweenPhotosKey = "waitBetweenPhotos"
    private let exposureTimeKey = "exposureTime"

    init(bleManager: BluetoothManager) {
        self.bleManager = bleManager

        let defaults = UserDefaults.standard
        self._numberOfPhotos = State(initialValue: defaults.integer(forKey: numberOfPhotosKey))
        self._waitBetweenPhotos = State(initialValue: defaults.double(forKey: waitBetweenPhotosKey))
        self._exposureTime = State(initialValue: defaults.double(forKey: exposureTimeKey))
    }

    var body: some View {
        Form {
            HStack {
                Text("number_of_photos".localized(comment: "Number of photos"))
                    .frame(width: 170, alignment: .leading)
                TextField("0", value: $numberOfPhotos, format: .number)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .numberOfPhotos)
                    .onChange(of: numberOfPhotos) { _, _ in
                        UserDefaults.standard.set(numberOfPhotos, forKey: numberOfPhotosKey)
                    }
            }

            HStack {
                Text("wait_between_photos".localized(comment: "Wait between photos"))
                    .frame(width: 170, alignment: .leading)
                TextField("0.0", value: $waitBetweenPhotos, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .waitBetweenPhotos)
                    .onChange(of: waitBetweenPhotos) { _, _ in
                        UserDefaults.standard.set(waitBetweenPhotos, forKey: waitBetweenPhotosKey)
                    }
            }

            HStack {
                Text("exposure_time".localized(comment: "Exposure time"))
                    .frame(width: 170, alignment: .leading)
                TextField("0.0", value: $exposureTime, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .exposureTime)
                    .onChange(of: exposureTime) { _, _ in
                        UserDefaults.standard.set(exposureTime, forKey: exposureTimeKey)
                    }
            }

            Button(action: {
                if self.isRunning {
                    self.isRunning = false
                } else {
                    self.isRunning = true
                    self.startIntervalometer()
                }
                focusedField = nil
            }) {
                Text(isRunning ? "stop".localized(comment: "Stop") : "start".localized(comment: "Start"))
            }
        }
        // Throws an error for some reason
//        .toolbar {
//            ToolbarItemGroup(placement: .keyboard) {
//                Spacer()
//                Button("done".localized(comment: "Done")) {
//                    focusedField = nil
//                }
//            }
//        }
    }

    func startIntervalometer() {
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<numberOfPhotos {
                if !self.isRunning {
                    break
                }

                DispatchQueue.main.async {
                    self.bleManager.takePhoto()
                }

                if exposureTime > 0 {
                    Thread.sleep(forTimeInterval: exposureTime)
                    DispatchQueue.main.async {
                        self.bleManager.takePhoto()
                    }
                }

                if i < numberOfPhotos - 1 && self.isRunning {
                    Thread.sleep(forTimeInterval: waitBetweenPhotos)
                }
            }

            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
}
