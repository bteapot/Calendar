//
//  CALayer+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 10.06.2021.
//

import Foundation
import UIKit


extension CALayer {
    func shiftAnchorPoint(to new: CGPoint) {
        let old: CGPoint = self.anchorPoint
        self.anchorPoint = new
        self.position =
            CGPoint(
                x: self.position.x + self.bounds.width  * (new.x - old.x),
                y: self.position.y + self.bounds.height * (new.y - old.y)
            )
    }
}
