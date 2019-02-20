//
//  DoneButton.swift
//  Internet Map
//
//  Created by Robert MacEachern on 2019-02-19.
//  Copyright © 2019 Peer1. All rights reserved.
//

import UIKit

class DoneButton: UIButton {

    private let xImage = UIImage(named: "x-icon")!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        imageView?.contentMode = .center
        setImage(xImage, for: .normal)
        backgroundColor = Theme.primary
        layer.cornerRadius = intrinsicContentSize.height / 2
    }

    override var intrinsicContentSize: CGSize {
        let width = xImage.size.width + 20
        let height = xImage.size.height + 20
        return CGSize(width: width, height: height)
    }
}
