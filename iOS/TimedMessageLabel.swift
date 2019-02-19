//
//  TimedMessageLabel.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2018-03-06.
//  Copyright © 2018 Peer1. All rights reserved.
//

import UIKit

public class TimedMessageLabel: UILabel {
    private var hidingTimer: Timer?

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        alpha = 0.0
    }

    @objc public func setErrorString(_ error: String) {
        text = error

        hidingTimer?.invalidate()
        hidingTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.hidingTimerFired), userInfo: nil, repeats: false)

        UIView.animate(withDuration: 0.75) {
            self.alpha = 1.0
        }
    }

    @objc private func hidingTimerFired() {
        UIView.animate(withDuration: 0.75) {
            self.alpha = 0.0
        }
    }
}
