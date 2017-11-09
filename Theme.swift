//
//  Theme.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2017-11-08.
//  Copyright © 2017 Peer1. All rights reserved.
//

import UIKit

// Note: these definitions are duplocates of the one in HelperMethods.h (since it's two hard to share them given how they are set up)
// if changes are made, will need to be changed in both places

enum Theme {
    static let blue = UIColor(red: 68.0 / 255.0, green: 144.0 / 255.0, blue: 206.0 / 255.0, alpha: 1.0)
    static let primary = Theme.blue

    static let fontNameLight = "NexaLight"
}

