//
//  UINavigationItem+Setup.swift
//  Calendar
//
//  Created by Денис Либит on 23.09.2020.
//

import Foundation
import UIKit


extension UINavigationItem {
    func setup() {
        self.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        self.standardAppearance = appearance
        self.scrollEdgeAppearance = appearance
        self.compactAppearance = appearance
        
        if #available(iOS 15.0, *) {
            self.compactScrollEdgeAppearance = appearance
        }
    }
}
