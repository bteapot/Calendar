//
//  Compact.DayVC.WeekdayLayer.swift
//  Calendar
//
//  Created by Денис Либит on 02.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Section.Compact.DayVC {
    final class WeekdayLayer: CALayer {
        
        // MARK: - Инициализация
        
        required init(
            info: CalendarVC.Info,
            date: Date
        ) {
            // параметры
            self.info = info
            self.date = date
            
            // инициализируемся
            super.init()
            
            // ставим данные
            self.update()
            
            // саблэера
            self.addSublayer(self.markerLayer)
            self.addSublayer(self.textLayer)
        }
        
        override init(layer: Any) {
            let layer = layer as! WeekdayLayer
            self.info = layer.info
            self.date = layer.date
            super.init(layer: layer)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Свойства
        
        let info: CalendarVC.Info
        let date: Date
        
        // MARK: - Саблеера
        
        private lazy var markerLayer: CALayer = {
            let layer = CALayer()
            layer.zPosition = 0
            layer.masksToBounds = true
            return layer
        }()
        
        private lazy var textLayer: CATextLayer = {
            let layer = CATextLayer()
            layer.zPosition = 1
            layer.alignmentMode = .center
            layer.contentsScale = UIScreen.main.scale
            return layer
        }()
        
        // MARK: - Данные
        
        func update() {
            // особые дни
            let isInWeekend: Bool = self.date.isInWeekend
            let isToday:     Bool = self.date.isToday
            let isSelected:  Bool = self.date.isEqual(to: self.info.date, precision: .day)
            
            // текст
            self.textLayer.string =
                NSAttributedString(
                    string: self.info.formatters.day.string(from: self.date),
                    attributes: [
                        .font: self.info.style.fonts.monthDay,
                        .foregroundColor: {
                            if isSelected {
                                return self.info.style.navbar.inverted
                            } else {
                                if isToday {
                                    return self.info.style.colors.tint
                                } else {
                                    if isInWeekend {
                                        return self.info.style.navbar.weekend
                                    } else {
                                        return self.info.style.navbar.primary
                                    }
                                }
                            }
                        }(),
                    ]
                )
            self.textLayer.setNeedsDisplay()
            
            // маркер сегодняшнего дня
            self.markerLayer.backgroundColor = {
                if isToday {
                    return self.info.style.colors.tint.cgColor
                }
                if isSelected {
                    return self.info.style.navbar.primary.cgColor
                }
                return nil
            }()
            self.markerLayer.isHidden = isSelected == false
        }
        
        // MARK: - Геометрия
        
        override func layoutSublayers() {
            let bounds:         CGRect = self.bounds
            let todayDiameter:  CGFloat = Self.todayDiameter(with: info)
            
            // маркер сегодняшнего дня
            self.markerLayer.bounds.size  = CGSize.square(todayDiameter)
            self.markerLayer.cornerRadius = todayDiameter / 2
            self.markerLayer.position     = bounds.center
            
            // текст
            self.textLayer.bounds.size = self.textLayer.preferredFrameSize()
            self.textLayer.position    = bounds.center
        }
        
        override func preferredFrameSize() -> CGSize {
            return CGSize.square(Self.height(with: self.info))
        }
        
        static func height(with info: CalendarVC.Info) -> CGFloat {
            let inset:          CGFloat = 2
            let todayDiameter:  CGFloat = Self.todayDiameter(with: info)
            
            return inset + todayDiameter + inset
        }
        
        private static func todayDiameter(with info: CalendarVC.Info) -> CGFloat {
            return info.style.fonts.monthDay.lineHeight.ceiled() + info.style.geometry.inset
        }
    }
}
