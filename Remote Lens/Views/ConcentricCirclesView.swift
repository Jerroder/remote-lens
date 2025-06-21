//
//  ConcentricCirclesView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import SwiftUI

struct ConcentricCirclesView: View {
    @State private var opacityValues: [Double] = [0.1, 0.1, 0.1]
    @State private var currentIndex = 0
    @State private var isWaiting = false
    
    let animationTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let waitTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(lineWidth: 2)
                    .frame(width: 10 + CGFloat(index) * 15, height: 10 + CGFloat(index) * 15)
                    .opacity(opacityValues[index])
            }
        }
        .frame(width: 150, height: 150)
        .onReceive(animationTimer) { _ in
            guard !isWaiting else {
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacityValues[2] = 0.1
                }
                return
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                opacityValues = [0.1, 0.1, 0.1]
                
                opacityValues[currentIndex] = 1
                
                currentIndex = (currentIndex + 1) % 3
                
                if currentIndex == 0 {
                    isWaiting = true
                }
            }
        }
        .onReceive(waitTimer) { _ in
            guard isWaiting else { return }
            isWaiting = false
        }
    }
}
