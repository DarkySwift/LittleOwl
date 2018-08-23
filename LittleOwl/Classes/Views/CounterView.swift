//
//  CounterView.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation
import UIKit

class CounterView: NibDesignableView {
    
    // MARK: - Properties
    
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var pointView: UIView!
    
    var timer: Timer?
    var remainingSeconds: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        pointView.layer.cornerRadius = pointView.frame.size.width / 2
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Methods
    
    @objc func updateCounter(_ timer: Timer?) {
        if remainingSeconds < 0 {
            self.timer?.invalidate()
            return
        }
        remainingSeconds -= 1
        elapsedTimeLabel.text = formattedRemainingSeconsString()
    }
    
    func formattedRemainingSeconsString() -> String? {
        let minutes: Int = (remainingSeconds % 3600) / 60
        let seconds: Int = (remainingSeconds % 3600) % 60
        return String(format: "%02lu:%02lu", minutes, seconds)
    }
    
    // MARK: - Public
    
    func startCounter(with seconds: Int) {
        timer?.invalidate()
        remainingSeconds = seconds
        
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(updateCounter(_:)),
                                     userInfo: nil,
                                     repeats: true)
        elapsedTimeLabel.text = formattedRemainingSeconsString()
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.autoreverse, .repeat], animations: {
            self.pointView.alpha = 0.0
        })
    }
}
