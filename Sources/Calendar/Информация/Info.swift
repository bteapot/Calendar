//
//  Info.swift
//  Calendar
//
//  Created by Денис Либит on 27.05.2021.
//

import Foundation
import ReactiveSwift


extension CalendarVC {
    public final class Info {
        
        // MARK: - Инициализация
        
        required init(
            style:         Style,
            dataSource:    DataSourceProtocol,
            selection:     Selection,
            customization: Customization
        ) {
            self.style         = style
            self.dataSource    = dataSource
            self.selection     = selection
            self.customization = customization
            
            self.update()
        }
        
        // MARK: - Свойства
        
        public let style:         Style
        public let dataSource:    DataSourceProtocol
        public let selection:     Selection
        public let customization: Customization
        
        public let formatters   = Formatters()
        public let metrics      = Metrics()
        public let interaction  = Interaction()
        
        public private(set) var zero = Date(timeIntervalSinceReferenceDate: 0).startOfYear
        public var date = Date()
        
        public func update() {
            self.zero = Date(timeIntervalSinceReferenceDate: 0).startOfYear
            self.formatters.update(with: Calendar.shared)
            self.metrics.update(with: Calendar.shared)
        }
    }
}

// MARK: - Форматтеры

extension CalendarVC.Info {
    public struct Formatters {
        fileprivate func update(with calendar: Foundation.Calendar) {
            self.update(self.year,          calendar: calendar, template: "y")                  // 2021
            self.update(self.month,         calendar: calendar, template: "LLLL")               // февраль (капитализировать)
            self.update(self.day,           calendar: calendar, template: "d")                  // 31
            self.update(self.hour,          calendar: calendar, template: "HHmm")               // 04:56
            self.update(self.monthShort,    calendar: calendar, template: "MMM")                // февр. (капитализировать)
            self.update(self.dayAndMonth,   calendar: calendar, template: "dMMM")               // 30 мая
            self.update(self.weekdayAndDay, calendar: calendar, template: "EEEEEEd")            // Ср, 30
            self.update(self.full,          calendar: calendar, template: "EEEE, MMM d, yyyy")  // среда, 2 июня 2021 г. (капитализировать)
        }
        
        private func update(_ formatter: DateFormatter, calendar: Foundation.Calendar, template: String) {
            formatter.dateFormat =
                DateFormatter.dateFormat(
                    fromTemplate: template,
                    options: 0,
                    locale: Locale.current
                )
        }
        
        public let year            = DateFormatter()
        public let month           = DateFormatter()
        public let day             = DateFormatter()
        public let hour            = DateFormatter()
        public let monthShort      = DateFormatter()
        public let dayAndMonth     = DateFormatter()
        public let weekdayAndDay   = DateFormatter()
        public let full            = DateFormatter()
    }
}

// MARK: - Метрики

extension CalendarVC.Info {
    public final class Metrics {
        public private(set) var daysInWeek:   Int = 7
        public private(set) var weeksInMonth: Int = 6
        public private(set) var monthsInYear: Int = 12
        public private(set) var firstWeekday: Int = 2
        public private(set) var weekends:     IndexSet = [6, 7]
        
        fileprivate func update(with calendar: Foundation.Calendar) {
            let maxWeekdaysRange = calendar.maximumRange(of: .weekday) ?? 1..<8
            
            var date = Date()
            var interval: TimeInterval = 0
            _ = calendar.dateInterval(of: .weekOfMonth, start: &date, interval: &interval, for: date)
            
            self.daysInWeek   = maxWeekdaysRange.count
            self.weeksInMonth = calendar.maximumRange(of: .weekOfMonth)?.count ?? 6
            self.monthsInYear = calendar.maximumRange(of: .month)?.count ?? 12
            self.firstWeekday = calendar.firstWeekday
            
            self.weekends =
                IndexSet(
                    maxWeekdaysRange
                        .filter({ weekday in
                            if  let day = date.adding(.day, value: weekday - maxWeekdaysRange.lowerBound),
                                calendar.isDateInWeekend(day)
                            {
                                return true
                            } else {
                                return false
                            }
                        })
                )
        }
    }
}

// MARK: - Пользовательские действия

extension CalendarVC.Info {
    public struct Interaction {
        let shown  = Signal<(SectionProtocol, Date), Never>.pipe()
        let tapped = Signal<(SectionProtocol, Date), Never>.pipe()
        let today  = Signal<(), Never>.pipe()
    }
}
