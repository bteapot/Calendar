//
//  Compact.MonthVC.Toolbar.swift
//  Calendar
//
//  Created by Денис Либит on 03.06.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


extension CalendarVC.Section.Compact.MonthVC {
    final class Toolbar: ToolbarView {
        
        // MARK: - Инициализация
        
        init(
            info: CalendarVC.Info
        ) {
            // параметры
            self.info = info
            
            // инициализируемся
            super.init(
                frame:     .zero,
                separator: .bottom,
                effect:    info.style.navbar.translucent ? .prominent : nil,
                color:     info.style.navbar.background
            )
            
            // добавим сабвьюхи
            self.addSubview(self.weekdayRuler)
        }
        
        @available(*, unavailable)
        required init(frame: CGRect, separator: ToolbarView.Separator, effect: UIBlurEffect.Style?, color: UIColor) { fatalError() }
        
        // MARK: - Свойства
        
        private let info: CalendarVC.Info
        
        // MARK: - Сабвьюхи
        
        lazy var weekdayRuler =
            CalendarVC.Section.Shared.RulerView<CATextLayer>(
                elements: Array(0..<self.info.metrics.daysInWeek)
                    .map { index in
                        let layer = CATextLayer()
                        layer.contentsScale = UIScreen.main.scale
                        layer.alignmentMode = .center
                        return layer
                    },
                height: self.info.style.fonts.dayRulerWeekday.lineHeight + self.info.style.geometry.inset
            )
        
        // MARK: - Данные
        
        func update() {
            let firstWeekday: Int =
                self.info.metrics.firstWeekday
            
            let weekends: IndexSet =
                self.info.metrics.weekends
            
            let weekdayRange: Range<Int> =
                Calendar.shared.maximumRange(of: .weekday) ?? 1..<8
            
            let weekdaySymbols: [String] =
                self.info.formatters.day.shortStandaloneWeekdaySymbols
                
            self.weekdayRuler.elements
                .enumerated()
                .forEach { weekdayIndex, layer in
                    let symbol: String =
                        weekdaySymbols[(firstWeekday + weekdayIndex - weekdayRange.lowerBound + weekdayRange.count) % weekdayRange.count]
                    
                    layer.string =
                        NSAttributedString(
                            string: symbol,
                            attributes: [
                                .font: self.info.style.fonts.dayRulerWeekday,
                                .foregroundColor: weekends.contains(weekdayRange.lowerBound + weekdayIndex) ? self.info.style.navbar.weekend : self.info.style.navbar.primary,
                            ]
                        )
                    
                    layer.setNeedsDisplay()
                }
            
            self.weekdayRuler.height =
                self.info.style.fonts.dayRulerWeekday.lineHeight + self.info.style.geometry.inset
        }
        
        // MARK: - Геометрия
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let bounds:             CGRect  = self.bounds
            let insetted:           CGRect  = bounds.inset(by: self.safeAreaInsets)
            let inset:              CGFloat = self.info.style.geometry.inset
            let weekdayRulerHeight: CGFloat = self.weekdayRuler.height
            
            self.weekdayRuler.frame =
                CGRect(
                    x:      insetted.minX,
                    y:      insetted.minY + inset / 2,
                    width:  insetted.width,
                    height: weekdayRulerHeight
                )
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let inset:              CGFloat = self.info.style.geometry.inset
            let weekdayRulerHeight: CGFloat = self.weekdayRuler.height
            
            return CGSize(
                width:  size.width,
                height: ceil(inset / 2 + weekdayRulerHeight + inset / 2)
            )
        }
    }
}
