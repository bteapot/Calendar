//
//  SectionDayVC.RulerView.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit


extension CalendarVC.Section.Regular.DayVC {
    final class RulerView: UIView {
        
        // MARK: - Инициализация
        
        required init(
            info: CalendarVC.Info,
            date: Date
        ) {
            // стиль
            self.info = info
            self.date = date
            
            // диапазон дат в неделе
            self.dates =
                Array(0..<self.info.metrics.daysInWeek)
                    .compactMap { date.adding(.day, value: $0) }
            
            // диаметр кружка
            self.circleRadius = Self.circleRadius(for: info)
            
            // инициализируемся
            super.init(frame: .zero)
            
            // свойства
            self.isOpaque = false
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Метрики
        
        static func height(for info: CalendarVC.Info) -> CGFloat {
            return self.circleRadius(for: info) * 2 + info.style.geometry.inset
        }
        
        private static func circleRadius(for info: CalendarVC.Info) -> CGFloat {
            let size: CGSize = "00".size(withAttributes: [.font: info.style.fonts.rulerDaySelected])
            return ceil(max(size.width, size.height) / 2 + 5)
        }
        
        // MARK: - Свойства
        
        let info: CalendarVC.Info
        let date: Date
        
        private let dates: [Date]
        private let circleRadius: CGFloat
        
        // MARK: - Отрисовка
        
        override func draw(_ rect: CGRect) {
            // контекст
            guard let context = UIGraphicsGetCurrentContext() else {
                return
            }
            
            // размеры
            let bounds: CGRect =
                self.bounds
            
            // ширина дня
            let dayWidth: CGFloat =
                bounds.width / CGFloat(self.info.metrics.daysInWeek)
            
            // нарисуем дни
            (0..<self.info.metrics.daysInWeek).forEach { dayOfWeek in
                // дата
                let date: Date = self.dates[dayOfWeek]
                
                let isInWeekend: Bool = date.isInWeekend
                let isToday:     Bool = date.isEqual(to: Date(), precision: .day)
                let isSelected:  Bool = date.isEqual(to: self.info.date, precision: .day)
                
                // атрибуты текста дня недели
                let weekdayAttributes: [NSAttributedString.Key: Any] = [
                    .font: self.info.style.fonts.rulerWeekday,
                    .foregroundColor: isInWeekend ? self.info.style.navbar.weekend : self.info.style.navbar.primary,
                ]
                
                // атрибуты текста дня
                let dayFont:  UIFont
                let dayColor: UIColor
                
                if isSelected {
                    dayFont  = self.info.style.fonts.rulerDaySelected
                    dayColor = self.info.style.navbar.inverted
                } else {
                    dayFont  = self.info.style.fonts.rulerDay
                    
                    if isToday {
                        dayColor = self.info.style.colors.tint
                    } else {
                        if isInWeekend {
                            dayColor = self.info.style.navbar.weekend
                        } else {
                            dayColor = self.info.style.navbar.primary
                        }
                    }
                }
                
                // атрибуты текста дня недели
                let dayAttributes: [NSAttributedString.Key: Any] = [
                    .font:            dayFont,
                    .foregroundColor: dayColor
                ]
                
                // текст
                let fullString: String = self.info.formatters.weekdayAndDay.string(from: date)
                let dayString:  String = self.info.formatters.day.string(from: date)
                
                let precedingString: String
                let followingString: String
                
                if let range: Range<String.Index> = fullString.range(of: dayString) {
                    precedingString = String(fullString[..<range.lowerBound])
                    followingString = String(fullString[range.upperBound...])
                } else {
                    precedingString = ""
                    followingString = ""
                }
                
                // размер текста
                let preceedingSize: CGSize = precedingString.size(withAttributes: weekdayAttributes)
                var daySize:        CGSize = dayString.size(withAttributes: dayAttributes)
                let followingSize:  CGSize = followingString.size(withAttributes: weekdayAttributes)
                
                let width: CGFloat = preceedingSize.width + daySize.width + followingSize.width
                
                // стартовая позиция
                let startX: CGFloat = dayWidth * CGFloat(dayOfWeek) + (dayWidth - width) / 2 - (isSelected ? 6 : 0)
                
                // отступы для кружка
                let circleInset: CGFloat
                let dayBump:     CGFloat
                
                // рисуем кружок
                if isSelected {
                    // дадим место для кружка
                    circleInset = self.circleRadius - daySize.width + 6
                    dayBump = -1
                    
                    daySize.width += circleInset
                    
                    // цвет кружка
                    let circleColor: UIColor = isToday ? self.info.style.colors.tint : self.info.style.navbar.primary
                    
                    // позиция кружка
                    let centerX:    CGFloat = startX + preceedingSize.width + daySize.width / 2
                    let centerY:    CGFloat = bounds.height / 2
                    let circleRect: CGRect  = CGRect(x: centerX - self.circleRadius, y: centerY - self.circleRadius, width: self.circleRadius * 2, height: self.circleRadius * 2)
                    
                    // рисуем
                    context.setFillColor(circleColor.cgColor)
                    context.fillEllipse(in: circleRect)
                } else {
                    circleInset = 0
                    dayBump     = 0
                }
                
                // рисуем текст
                precedingString
                    .draw(
                        at: CGPoint(
                            x: startX,
                            y: (bounds.height - preceedingSize.height) / 2
                        ),
                        withAttributes: weekdayAttributes
                    )
                dayString
                    .draw(
                        at: CGPoint(
                            x: startX + preceedingSize.width + circleInset / 2,
                            y: (bounds.height - daySize.height) / 2 + dayBump
                        ),
                        withAttributes: dayAttributes
                    )
                followingString
                    .draw(
                        at: CGPoint(
                            x: startX + preceedingSize.width + daySize.width + circleInset,
                            y: (bounds.height - followingSize.height) / 2
                        ),
                        withAttributes: weekdayAttributes
                    )
            }
        }
        
        // MARK: - Геометрия
        
        override func layoutSubviews() {
            self.setNeedsDisplay()
        }
        
        // MARK: - Инструменты
        
        func date(at point: CGPoint) -> Date? {
            guard self.bounds.contains(point) else {
                return nil
            }
            
            let index = Int((point.x / self.bounds.width) * CGFloat(self.info.metrics.daysInWeek))
            return self.dates[index]
        }
    }
}
