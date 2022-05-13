//
//  Flip.swift
//  
//
//  Created by Денис Либит on 04.05.2022.
//

import Foundation
import CoreGraphics
import UIKit


extension CGAffineTransform {
    static func flip(for width: CGFloat) -> Self {
        return CGAffineTransform(
            a:  -1,
            b:  0,
            c:  0,
            d:  1,
            tx: width,
            ty: 0
        )
    }
}

extension CGRect {
    func flip(if needed: Bool, with width: CGFloat) -> CGRect {
        return needed ? self.applying(CGAffineTransform.flip(for: width)) : self
    }
}

extension CGPoint {
    func flip(if needed: Bool, with width: CGFloat) -> CGPoint {
        return needed ? self.applying(CGAffineTransform.flip(for: width)) : self
    }
}

extension CALayer {
    func flipLayoutIfNeeded() {
        guard UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft else {
            return
        }
        
        let transform = CGAffineTransform.flip(for: self.bounds.width)
        
        self.sublayers?.forEach { sublayer in
            sublayer.frame = sublayer.frame.applying(transform)
        }
    }
}

extension UIView {
    func flipLayoutIfNeeded() {
        guard UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft else {
            return
        }
        
        let transform = CGAffineTransform.flip(for: self.bounds.width)
        
        self.subviews.forEach { subview in
            subview.frame = subview.frame.applying(transform)
        }
    }
}
