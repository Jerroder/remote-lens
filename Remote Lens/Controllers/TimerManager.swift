//
//  TimerManager.swift
//  Remote Lens
//
//  Created by Jerroder on 2025-06-25.
//

import Foundation

class TimerManager: ObservableObject {
    @Published private var timer: Timer?

    func startTimer(interval: TimeInterval, action: @escaping () -> Void) {
        stopTimer()
        
        action()
        
        if interval > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard self != nil else { return }
                action()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
