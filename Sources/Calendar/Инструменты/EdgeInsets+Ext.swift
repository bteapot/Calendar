//
//  EdgeInsets+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 23.07.2021.
//

import SwiftUI


extension EdgeInsets {
	init(
        all:      CGFloat = 0,
        top:      CGFloat? = nil,
        leading:  CGFloat? = nil,
        bottom:   CGFloat? = nil,
        trailing: CGFloat? = nil
    ) {
		self.init(
            top:      top      ?? all,
            leading:  leading  ?? all,
            bottom:   bottom   ?? all,
            trailing: trailing ?? all
        )
	}
	
    init(
        horizontal: CGFloat = 0,
        vertical:   CGFloat = 0
    ) {
        self.init(
            top:      vertical,
            leading:  horizontal,
            bottom:   vertical,
            trailing: horizontal
        )
    }
    
	func with(
        top:      CGFloat? = nil,
        leading:  CGFloat? = nil,
        bottom:   CGFloat? = nil,
        trailing: CGFloat? = nil
    ) -> EdgeInsets {
		return EdgeInsets(
            top:      top      ?? self.top,
            leading:  leading  ?? self.leading,
            bottom:   bottom   ?? self.bottom,
            trailing: trailing ?? self.trailing
        )
	}
	
	var vertical: CGFloat {
		return self.top + self.bottom
	}
	
	var horizontal: CGFloat {
		return self.leading + self.trailing
	}
}
