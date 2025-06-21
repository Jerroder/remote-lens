//
//  AnimatedArrowheadsView.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-21.
//

import SwiftUI

struct Arrowhead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let leftPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let topPoint = CGPoint(x: rect.midX, y: rect.minY)
        let rightPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        
        path.move(to: leftPoint)
        path.addLine(to: topPoint)
        path.move(to: rightPoint)
        path.addLine(to: topPoint)
        
        return path
    }
}

struct AnimatedArrowheadsView: View {
    @State private var opacityValues: [Double] = [0.1, 0.1, 0.1]
    @State private var currentIndex = 2
    @State private var isWaiting = false
    
    let animationTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let waitTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                ForEach(0..<4) { i in
                    VStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Arrowhead()
                                .stroke(lineWidth: 2)
                                .frame(width: 20 + CGFloat(index) * 3, height: 8)
                                .opacity(self.opacityValues[index])
                        }
                    }
                    .rotationEffect(self.rotationAngleForIndex(i))
                    .position(self.positionForIndex(i, center: center))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: 200, height: 200)
        .onReceive(animationTimer) { _ in
            guard !isWaiting else {
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacityValues[0] = 0.1
                }
                return
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                opacityValues = [0.1, 0.1, 0.1]
                
                opacityValues[currentIndex] = 1
                
                currentIndex = (currentIndex - 1 + 3) % 3
                
                if currentIndex == 2 {
                    isWaiting = true
                }
            }
        }
        .onReceive(waitTimer) { _ in
            guard isWaiting else { return }
            isWaiting = false
        }
    }
    
    func rotationAngleForIndex(_ index: Int) -> Angle {
        return Angle(degrees: Double(index) * 90)
    }
    
    func positionForIndex(_ index: Int, center: CGPoint) -> CGPoint {
        let hOffset: CGFloat = 115
        let vOffset: CGFloat = 140
        
        switch index {
        case 0: // Top
            return CGPoint(x: center.x, y: center.y - vOffset)
        case 1: // Right
            return CGPoint(x: center.x + hOffset, y: center.y)
        case 2: // Bottom
            return CGPoint(x: center.x, y: center.y + vOffset)
        case 3: // Left
            return CGPoint(x: center.x - hOffset, y: center.y)
        default:
            return center
        }
    }
}
