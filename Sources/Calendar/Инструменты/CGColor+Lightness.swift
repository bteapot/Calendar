//
//  CGColor+Lightness.swift
//  Calendar
//
//  Created by Денис Либит on 26/09/2019.
//

import CoreGraphics


extension CGColor {
    var white: CGFloat {
        let rgb = self.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        
        guard
            let components = rgb?.components,
            components.count >= 3
        else {
            return 0
        }
        
        let w: CGFloat = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return w
    }
}
