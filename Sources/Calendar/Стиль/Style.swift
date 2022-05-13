//
//  Style.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit


extension CalendarVC {
    public struct Style {
        public var colors   = Colors()
        public var fonts    = Fonts()
        public var geometry = Geometry()
        public var navbar   = Navbar()
    }
}

extension CalendarVC {
    public struct Colors {
        // общие цвета
        public var background:            UIColor = .systemBackground
        public var primary:               UIColor = .label
        public var secondary:             UIColor = .secondaryLabel
        public var weekend:               UIColor = .secondaryLabel
        public var inverted:              UIColor = .systemBackground
        public var separator:             UIColor = .opaqueSeparator
        
        // выделенные элементы
        public var tint:                  UIColor = Self.defaultTint
        
        // переключатель секций
        public var switcherTitleNormal:   UIColor = Self.defaultTint
        public var switcherTitleSelected: UIColor = Self.defaultTint
    }
}

extension CalendarVC {
    public struct Navbar {
        public var translucent: Bool    = true
        public var background:  UIColor = .clear
        public var primary:     UIColor = .label
        public var weekend:     UIColor = .secondaryLabel
        public var inverted:    UIColor = .systemBackground
    }
}

extension CalendarVC {
    public struct Fonts {
        // метка текущего периода
        public var regularPeriod:     UIFont = .systemFont(ofSize: 18)
        public var regularPeriodBold: UIFont = .boldSystemFont(ofSize: 18)
        public var compactPeriod:     UIFont = .systemFont(ofSize: 16)
        
        // линейка дней недели
        public var rulerWeekday:      UIFont = .systemFont(ofSize: 16)
        public var rulerDay:          UIFont = .systemFont(ofSize: 16)
        public var rulerDaySelected:  UIFont = .boldSystemFont(ofSize: 16)
        
        // секция день
        public var dayAllday:         UIFont = .systemFont(ofSize: 12)
        public var dayTime:           UIFont = .systemFont(ofSize: 12)
        public var dayRulerWeekday:   UIFont = .systemFont(ofSize: 10)
        
        // секция месяц
        public var monthMonth:        UIFont = .boldSystemFont(ofSize: 24)
        public var monthDay:          UIFont = .systemFont(ofSize: 17)
        
        // секция год
        public var yearYear:          UIFont = .boldSystemFont(ofSize: 48)
        public var yearWeekday:       UIFont = .systemFont(ofSize: 12).with(weight: .light)
        
        // события
        public var eventNormal:       UIFont = .systemFont(ofSize: 13).with(weight: .semibold)
        public var eventSmall:        UIFont = .systemFont(ofSize: 11)
    }
}

extension CalendarVC {
    public struct Geometry {
        // отступы
        public var inset: CGFloat = 8
    }
}

extension CalendarVC.Style {
    public static let `default` = Self()
    
    public func copy(_ change: (inout Self) -> Void) -> Self {
        var copy = self
        change(&copy)
        return copy
    }
}

private extension CalendarVC.Colors {
    // дефолтные
    static let defaultTintBase =
        UIColor(hue: 0.00, saturation: 1.00, brightness: 0.95, alpha: 1)
    
    static let defaultTint =
        UIColor(
            light: Self.defaultTintBase,
            dark:  Self.defaultTintBase
                .brightened(by: 0.3)
                .saturated(by: -0.1)
        )
}
