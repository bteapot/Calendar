//
//  UIColor+Theme.swift
//  Calendar
//
//  Created by Денис Либит on 26.11.2020.
//

import UIKit


extension UIColor {
    convenience init(light: UIColor, dark:  UIColor) {
        self.init(dynamicProvider: { (provider: UITraitCollection) -> UIColor in
            switch provider.userInterfaceStyle {
            case .unspecified:      return light
            case .light:            return light
            case .dark:              return dark
            @unknown default:       return light
            }
        })
    }
}
