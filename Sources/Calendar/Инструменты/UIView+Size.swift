//
//  UIView+Size.swift
//  Calendar
//
//  Created by Денис Либит on 23.09.2020.
//

import Foundation
import UIKit


public extension UIView {
    func sizeThatFits(
        width:  CGFloat = 0,
        height: CGFloat = 0
    ) -> CGSize {
        return self.sizeThatFits(
            CGSize(
                width:  width,
                height: height
            )
        )
    }
}
