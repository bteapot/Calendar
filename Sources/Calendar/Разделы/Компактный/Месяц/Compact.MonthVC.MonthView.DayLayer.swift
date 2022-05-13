//
//  Compact.MonthVC.MonthView.DayLayer.swift
//  Calendar
//
//  Created by Денис Либит on 02.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Section.Compact.MonthVC.MonthView {
    final class DayLayer: CALayer {
        
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
            
            // свойства
            self.eventsLayer.date = date
            
            // саблэера
            self.addSublayer(self.todayLayer)
            self.addSublayer(self.textLayer)
            self.addSublayer(self.eventsLayer)
        }
        
        override init(layer: Any) {
            let layer = layer as! DayLayer
            self.info = layer.info
            self.date = layer.date
            super.init(layer: layer)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Свойства
        
        let info: CalendarVC.Info
        let date: Date
        
        // MARK: - Саблэера
        
        lazy var todayLayer: CALayer = {
            let layer = CALayer()
            layer.zPosition = 0
            layer.masksToBounds = true
            return layer
        }()
        
        lazy var textLayer: CATextLayer = {
            let layer = CalendarVC.Section.Shared.CenteredTextLayer()
            layer.zPosition = 1
            layer.alignmentMode = .center
            layer.contentsScale = UIScreen.main.scale
            return layer
        }()
        
        lazy var eventsLayer =
            self.info.customization.marker.init()
        
        // MARK: - Данные
        
        enum Transitioning {
            case none
            case native
            case foreign
        }
        
        func update(transitioning: Transitioning = .none) {
            // сегодня?
            let isInWeekend: Bool = self.date.isInWeekend
            let isToday:     Bool = self.date.isToday
            
            // текст
            self.textLayer.string = self.info.formatters.day.string(from: self.date)
            self.textLayer.font = self.info.style.fonts.monthDay
            self.textLayer.fontSize = self.info.style.fonts.monthDay.pointSize
            
            switch transitioning {
                case .none:
                    // текст
                    self.textLayer.foregroundColor = {
                        if isToday {
                            return self.info.style.colors.inverted.cgColor
                        } else {
                            if isInWeekend {
                                return self.info.style.colors.weekend.cgColor
                            } else {
                                return self.info.style.colors.primary.cgColor
                            }
                        }
                    }()
                    
                    // маркер сегодняшнего дня
                    self.todayLayer.backgroundColor = self.info.style.colors.tint.cgColor
                    self.todayLayer.opacity = isToday ? 1 : 0
                    
                    // маркер наличия событий
                    self.eventsLayer.set(style: self.info.style)
                    self.eventsLayer.opacity = 1
                    
                case .native:
                    // текст
                    self.textLayer.foregroundColor = {
                        if isToday {
                            return self.info.style.colors.inverted.cgColor
                        } else {
                            if isInWeekend {
                                return self.info.style.colors.weekend.cgColor
                            } else {
                                return self.info.style.colors.primary.cgColor
                            }
                        }
                    }()
                    
                    // маркер сегодняшнего дня
                    self.todayLayer.opacity = isToday ? 1 : 0
                    
                    // маркер наличия событий
                    self.eventsLayer.set(style: self.info.style)
                    self.eventsLayer.opacity = 1
                    
                case .foreign:
                    let isSelected: Bool = self.date.isEqual(to: self.info.date, precision: .day)
                    
                    // текст
                    self.textLayer.foregroundColor = {
                        if isSelected {
                            return self.info.style.navbar.inverted.cgColor
                        } else {
                            if isToday {
                                return self.info.style.colors.tint.cgColor
                            } else {
                                if isInWeekend {
                                    return self.info.style.navbar.weekend.cgColor
                                } else {
                                    return self.info.style.navbar.primary.cgColor
                                }
                            }
                        }
                    }()
                    
                    // маркер сегодняшнего дня
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.todayLayer.backgroundColor = isToday ? self.info.style.colors.tint.cgColor : self.info.style.navbar.primary.cgColor
                    CATransaction.commit()
                    
                    self.todayLayer.opacity = isSelected ? 1 : 0
                    
                    // маркер наличия событий
                    self.eventsLayer.opacity = 0
            }
        }
        
        var events: [CalendarEventProtocol] = [] {
            didSet {
                self.eventsLayer.set(events: self.events)
            }
        }
        
        // MARK: - Геометрия
        
        var freezeLayout: Bool = false
        
        override func layoutSublayers() {
            // идёт анимация перехода?
            guard self.freezeLayout == false else {
                return
            }
            
            let bounds:         CGRect  = self.bounds
            let inset:          CGFloat = self.info.style.geometry.inset / 2
            let todayDiameter:  CGFloat = Self.todayDiameter(with: self.info)
            let eventsHeight:   CGFloat = inset * 6
            
            // маркер сегодняшнего дня
            self.todayLayer.bounds.size  = CGSize.square(todayDiameter)
            self.todayLayer.cornerRadius = todayDiameter / 2
            self.todayLayer.position =
                CGPoint(
                    x: bounds.midX,
                    y: inset + todayDiameter / 2
                )
            
            // текст
            self.textLayer.frame =
                CGRect(
                    x:      0,
                    y:      self.todayLayer.frame.minY,
                    width:  bounds.width - inset,
                    height: self.todayLayer.frame.height
                )
            self.textLayer.position =
                self.todayLayer.position
            
            // маркер наличия событий
            self.eventsLayer.frame =
                CGRect(
                    x:      bounds.minX,
                    y:      bounds.maxY - eventsHeight,
                    width:  bounds.width,
                    height: eventsHeight
                )
        }
        
        func width() -> CGFloat {
            let inset: CGFloat = self.info.style.geometry.inset / 2
            
            return max(
                self.textLayer.preferredFrameSize().width,
                Self.todayDiameter(with: self.info)
            ) + inset
        }
        
        static func height(with info: CalendarVC.Info) -> CGFloat {
            let inset:          CGFloat = info.style.geometry.inset / 2
            let todayDiameter:  CGFloat = Self.todayDiameter(with: info)
            let eventsDiameter: CGFloat = 8
            
            return inset + todayDiameter + inset / 2 + eventsDiameter + inset * 2.5
        }
        
        static func todayDiameter(with info: CalendarVC.Info) -> CGFloat {
            return info.style.fonts.monthDay.lineHeight.ceiled() + info.style.geometry.inset
        }
    }
}
