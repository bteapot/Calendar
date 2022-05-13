//
//  CGSize+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 27.07.2020.
//

import CoreGraphics
import UIKit


public extension CGSize {
    static func square(_ side: CGFloat) -> CGSize {
        return CGSize(width: side, height: side)
    }
    
    func floored() -> CGSize {
        CGSize(
            width:  floor(self.width),
            height: floor(self.height)
        )
    }
    
    func ceiled() -> CGSize {
        CGSize(
            width:  ceil(self.width),
            height: ceil(self.height)
        )
    }
    
    func insetted(by insets: UIEdgeInsets) -> CGSize {
        CGSize(
            width:  Swift.max(0, self.width  - insets.left - insets.right),
            height: Swift.max(0, self.height - insets.top  - insets.bottom)
        )
    }
    
    func expanded(by insets: UIEdgeInsets) -> CGSize {
        CGSize(
            width:  Swift.max(0, self.width  + insets.left + insets.right),
            height: Swift.max(0, self.height + insets.top  + insets.bottom)
        )
    }
    
    var ratio: CGFloat {
        self.width / self.height
    }
}
