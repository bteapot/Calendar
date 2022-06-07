//
//  CGPoint+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 28.08.2020.
//

import Foundation
import UIKit


extension CGPoint {
    func floored() -> CGPoint {
        return CGPoint(x: floor(self.x), y: floor(self.y))
    }

    func ceiled() -> CGPoint {
        return CGPoint(x: ceil(self.x),  y: ceil(self.y))
    }

    func squaredDistance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return dx * dx + dy * dy
    }

    func offset(from point: CGPoint) -> UIOffset {
        return UIOffset(
            horizontal: point.x - self.x,
            vertical:   point.y - self.y
        )
    }

    func shift(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(
            x: self.x + x,
            y: self.y + y
        )
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        return  CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}
