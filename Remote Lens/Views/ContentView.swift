//
//  ContentView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-10.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            OneShotView().tabItem {
                Image(systemName: "camera")
                Text("one_shot".localized(comment: "One Shot"))
            }

            IntervalometerView().tabItem {
                Image(systemName: "timer")
                Text("intervalometer".localized(comment: "Intervalometer"))
            }
        }
    }
}
