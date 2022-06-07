//
//  UIColor+Lightness.swift
//  Calendar
//
//  Created by Денис Либит on 26/09/2019.
//

import UIKit


extension UIColor {
    func saturated(by value: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return UIColor(hue: h, saturation: min(1, max(0, s + value)), brightness: b, alpha: a)
    }
    
    func brightened(by value: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return UIColor(hue: h, saturation: s, brightness: min(1, max(0, b + value)), alpha: a)
    }
    
    var white: CGFloat {
        var w: CGFloat = 0, a: CGFloat = 0
        guard self.getWhite(&w, alpha: &a) else { return 0 }
        return w
    }
}
