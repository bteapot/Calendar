//
//  Navigator.swift
//  Calendar
//
//  Created by Денис Либит on 27.05.2021.
//

import Foundation
import UIKit


protocol NavigatorProtocol {
    func viewDidLoad()
    func layoutSubviews()
    func traitsChanged()
    
    func reload()
    func update()
    
    func set(hidden: Bool, animated: Bool)
}

extension CalendarVC {
    public struct Navigator {}
}

extension CalendarVC.Navigator {
    public enum Kind {
        case regular
        case compact
    }
}

extension CalendarVC.Navigator.Kind {
    public static var auto: Self {
        return UIDevice.current.userInterfaceIdiom == .pad ? .regular : .compact
    }
}
