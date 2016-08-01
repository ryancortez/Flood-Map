//
//  BlurView.swift
//  Flood Map
//
//  Created by Ryan Cortez on 7/28/16.
//  Copyright © 2016 Ryan Cortez. All rights reserved.
//

import UIKit

class BlurView: UIVisualEffectView {

    func blurBackground(withStyle style: UIBlurEffectStyle) {
        self.backgroundColor = UIColor.clearColor()
        self.effect = UIBlurEffect(style: style)
    }
}
