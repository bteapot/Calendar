//
//  Shared.CenteredTextLayer.swift
//  
//
//  Created by Денис Либит on 14.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Section.Shared {
    final class CenteredTextLayer: CATextLayer {
        override public func draw(in ctx: CGContext) {
            guard let font = self.font as? UIFont else {
                return
            }
            
            // коэффициент масштабирования
            let ratio: CGFloat =
                self.fontSize / font.pointSize
            
            // выравнивание по центру прописных букв
            let shift: CGFloat =
                (self.bounds.height - (font.lineHeight - font.ascender - font.descender + font.capHeight) * ratio) / 2
            
            ctx.saveGState()
            ctx.translateBy(x: 0, y: shift)
            super.draw(in: ctx)
            ctx.restoreGState()
        }
    }
}
