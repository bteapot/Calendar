//
//  CGRect+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 27.07.2020.
//

import CoreGraphics
import UIKit


public extension CGRect {
    func floored() -> CGRect {
        CGRect(
            x:      ceil(self.minX),
            y:      ceil(self.minY),
            width:  floor(self.width),
            height: floor(self.height)
        )
    }
    
    func ceiled() -> CGRect {
        CGRect(
            x:      floor(self.minX),
            y:      floor(self.minY),
            width:  ceil(self.width),
            height: ceil(self.height)
        )
    }
    
    var ratio: CGFloat {
        self.width / self.height
    }
    
    var center: CGPoint {
        CGPoint(
            x: self.midX,
            y: self.midY
        )
    }
    
    func expanded(by insets: UIEdgeInsets) -> CGRect {
        CGRect(
            x:      self.minX   - insets.left,
            y:      self.minY   - insets.top,
            width:  self.width  + insets.horizontal,
            height: self.height + insets.vertical
        )
    }
    
}
