//
//  UIEdgeInsets+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 27.07.2020.
//

import UIKit


public extension UIEdgeInsets {
	init(
        all:    CGFloat = 0,
        top:    CGFloat? = nil,
        left:   CGFloat? = nil,
        bottom: CGFloat? = nil,
        right:  CGFloat? = nil
    ) {
		self.init(
            top:    top    ?? all,
            left:   left   ?? all,
            bottom: bottom ?? all,
            right:  right  ?? all
        )
	}
	
    init(
        horizontal: CGFloat = 0,
        vertical:   CGFloat = 0
    ) {
        self.init(
            top:    vertical,
            left:   horizontal,
            bottom: vertical,
            right:  horizontal
        )
    }
    
	func with(
        top:    CGFloat? = nil,
        left:   CGFloat? = nil,
        bottom: CGFloat? = nil,
        right:  CGFloat? = nil
    ) -> UIEdgeInsets {
		return UIEdgeInsets(
            top:    top    ?? self.top,
            left:   left   ?? self.left,
            bottom: bottom ?? self.bottom,
            right:  right  ?? self.right
        )
	}
	
	var vertical: CGFloat {
		return self.top + self.bottom
	}
	
	var horizontal: CGFloat {
		return self.left + self.right
	}
}
