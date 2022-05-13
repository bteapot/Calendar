//
//  UIFont+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 27.07.2020.
//

import Foundation
import UIKit


public extension UIFont {
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if let fontDescriptor = self.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: fontDescriptor, size: self.pointSize)
        } else {
            return self
        }
    }
    
    func with(weight: UIFont.Weight) -> UIFont {
        let fontDescriptor = self.fontDescriptor.addingAttributes([
            .traits: [
                UIFontDescriptor.TraitKey.weight: weight,
            ],
        ])
        return UIFont(descriptor: fontDescriptor, size: self.pointSize)
    }
    
    func scaled(by ratio: CGFloat) -> UIFont {
        return UIFont(
            descriptor: self.fontDescriptor,
            size: self.pointSize * ratio
        )
    }
}
