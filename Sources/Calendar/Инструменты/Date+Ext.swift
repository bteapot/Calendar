//
//  Date+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 25.09.2017.
//

import Foundation


extension Calendar {
    static var shared: Calendar = Calendar.autoupdatingCurrent
}

extension Date {
    
    // MARK: - Граничные значения
    
    func start(of component: Calendar.Component) -> Date {
        var date:        Date            = self
        var interval:    TimeInterval    = 0
        
        if Calendar.shared.dateInterval(of: component, start: &date, interval: &interval, for: self) {
            return date
        } else {
            #if DEBUG
            NSLog("can't process date \(self)")
            #endif
            
            return self
        }
    }
    
    var startOfSecond:  Date { return self.start(of: .second) }
    var startOfMinute:  Date { return self.start(of: .minute) }
    var startOfHour:    Date { return self.start(of: .hour) }
    var startOfDay:     Date { return self.start(of: .day) }
    var startOfWeek:    Date { return self.start(of: .weekOfMonth) }
    var startOfMonth:   Date { return self.start(of: .month) }
    var startOfQuarter: Date { return self.start(of: .quarter) }
    var startOfYear:    Date { return self.start(of: .year) }
    
    func end(of component: Calendar.Component) -> Date {
        var date:     Date            = self
        var interval: TimeInterval    = 0
        
        if Calendar.shared.dateInterval(of: component, start: &date, interval: &interval, for: self) {
            return date.addingTimeInterval(interval)
        } else {
            #if DEBUG
            NSLog("can't process date \(self)")
            #endif
            
            return self
        }
    }
    
    var endOfSecond:    Date { return self.end(of: .second) }
    var endOfMinute:    Date { return self.end(of: .minute) }
    var endOfHour:      Date { return self.end(of: .hour) }
    var endOfDay:       Date { return self.end(of: .day) }
    var endOfWeek:      Date { return self.end(of: .weekOfMonth) }
    var endOfMonth:     Date { return self.end(of: .month) }
    var endOfQuarter:   Date { return self.end(of: .quarter) }
    var endOfYear:      Date { return self.end(of: .year) }
    
    // MARK: - Количество элементов
    
    var daysInWeek:     Int { return Calendar.shared.range(of: .weekday,     in: .weekOfMonth, for: self)?.count ?? 0 }
    var daysInMonth:    Int { return Calendar.shared.range(of: .day,         in: .month,       for: self)?.count ?? 0 }
    var daysInYear:     Int { return Calendar.shared.range(of: .day,         in: .year,        for: self)?.count ?? 0 }
    var weeksInMonth:   Int { return Calendar.shared.range(of: .weekOfMonth, in: .month,       for: self)?.count ?? 0 }
    var weeksInYear:    Int { return Calendar.shared.range(of: .weekOfYear,  in: .year,        for: self)?.count ?? 0 }
    
    // MARK: - Компоненты
    
    var second:             Int { return Calendar.shared.component(.second,             from: self) }
    var minute:             Int { return Calendar.shared.component(.minute,             from: self) }
    var hour:               Int { return Calendar.shared.component(.hour,               from: self) }
    var day:                Int { return Calendar.shared.component(.day,                from: self) }
    var month:              Int { return Calendar.shared.component(.month,              from: self) }
    var quarter:            Int { return (self.month - 1) / 3 + 1 }
    var year:               Int { return Calendar.shared.component(.year,               from: self) }
    var era:                Int { return Calendar.shared.component(.era,                from: self) }
    
    var weekday:            Int { return Calendar.shared.component(.weekday,            from: self) }
    var weekdayOrdinal:     Int { return Calendar.shared.component(.weekdayOrdinal,     from: self) }
    var weekOfMonth:        Int { return Calendar.shared.component(.weekOfMonth,        from: self) }
    var weekOfYear:         Int { return Calendar.shared.component(.weekOfYear,         from: self) }
    var yearForWeekOfYear:  Int { return Calendar.shared.component(.yearForWeekOfYear,  from: self) }
    
    // MARK: - Замена компонентов
    
    func replace(_ component: Calendar.Component, with value: Int) -> Date? {
        let all: Set<Calendar.Component> = [.era, .year, .month, .day, .hour, .minute, .second, .nanosecond, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear]
        var components: DateComponents = Calendar.shared.dateComponents(all, from: self)
        
        switch component {
        case .era:               components.era               = value
        case .year:              components.year              = value
        case .month:             components.month             = value
        case .day:               components.day               = value
        case .hour:              components.hour              = value
        case .minute:            components.minute            = value
        case .second:            components.second            = value
        case .nanosecond:        components.nanosecond        = value
        case .weekday:           components.weekday           = value
        case .weekdayOrdinal:    components.weekdayOrdinal    = value
        case .quarter:           components.quarter           = value
        case .weekOfMonth:       components.weekOfMonth       = value
        case .weekOfYear:        components.weekOfYear        = value
        case .yearForWeekOfYear: components.yearForWeekOfYear = value
        default:                 break
        }
        
        return Calendar.shared.date(from: components)
    }
    
    // MARK: - Арифметика
    
    func adding(_ component: Calendar.Component, value: Int) -> Date? {
        var components = DateComponents()
        
        switch component {
        case .era:               components.era               = value
        case .year:              components.year              = value
        case .month:             components.month             = value
        case .day:               components.day               = value
        case .hour:              components.hour              = value
        case .minute:            components.minute            = value
        case .second:            components.second            = value
        case .nanosecond:        components.nanosecond        = value
        case .weekday:           components.weekday           = value
        case .weekdayOrdinal:    components.weekdayOrdinal    = value
        case .quarter:           components.quarter           = value
        case .weekOfMonth:       components.weekOfMonth       = value
        case .weekOfYear:        components.weekOfYear        = value
        case .yearForWeekOfYear: components.yearForWeekOfYear = value
        default:                 break
        }
        
        return Calendar.shared.date(byAdding: components, to: self)
    }
    
    func subtracting(_ component: Calendar.Component, value: Int) -> Date? {
        var components = DateComponents()
        
        switch component {
        case .era:               components.era               = -value
        case .year:              components.year              = -value
        case .month:             components.month             = -value
        case .day:               components.day               = -value
        case .hour:              components.hour              = -value
        case .minute:            components.minute            = -value
        case .second:            components.second            = -value
        case .nanosecond:        components.nanosecond        = -value
        case .weekday:           components.weekday           = -value
        case .weekdayOrdinal:    components.weekdayOrdinal    = -value
        case .quarter:           components.quarter           = -value
        case .weekOfMonth:       components.weekOfMonth       = -value
        case .weekOfYear:        components.weekOfYear        = -value
        case .yearForWeekOfYear: components.yearForWeekOfYear = -value
        default:                 break
        }
        
        return Calendar.shared.date(byAdding: components, to: self)
    }
    
    // MARK: - Сравнение
    
    var isToday: Bool {
        return Calendar.shared.isDateInToday(self)
    }
    
    var isInWeekend: Bool {
        return Calendar.shared.isDateInWeekend(self)
    }
    
    func isEqual(to date: Date, precision: Calendar.Component) -> Bool {
        return Calendar.shared.isDate(self, equalTo: date, toGranularity: precision)
    }
    
    
    // MARK: - Прошедшее от даты время
    
    func years  (from date: Date) -> Int { Calendar.shared.dateComponents([.year],        from: date, to: self).year        ?? 0 }
    func months (from date: Date) -> Int { Calendar.shared.dateComponents([.month],       from: date, to: self).month       ?? 0 }
    func weeks  (from date: Date) -> Int { Calendar.shared.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0 }
    func days   (from date: Date) -> Int { Calendar.shared.dateComponents([.day],         from: date, to: self).day         ?? 0 }
    func hours  (from date: Date) -> Int { Calendar.shared.dateComponents([.hour],        from: date, to: self).hour        ?? 0 }
    func minutes(from date: Date) -> Int { Calendar.shared.dateComponents([.minute],      from: date, to: self).minute      ?? 0 }
    func seconds(from date: Date) -> Int { Calendar.shared.dateComponents([.second],      from: date, to: self).second      ?? 0 }
    
    // MARK: - Оставшееся до даты время
    
    func years  (to   date: Date) -> Int { Calendar.shared.dateComponents([.year],        from: self, to: date).year        ?? 0 }
    func months (to   date: Date) -> Int { Calendar.shared.dateComponents([.month],       from: self, to: date).month       ?? 0 }
    func weeks  (to   date: Date) -> Int { Calendar.shared.dateComponents([.weekOfMonth], from: self, to: date).weekOfMonth ?? 0 }
    func days   (to   date: Date) -> Int { Calendar.shared.dateComponents([.day],         from: self, to: date).day         ?? 0 }
    func hours  (to   date: Date) -> Int { Calendar.shared.dateComponents([.hour],        from: self, to: date).hour        ?? 0 }
    func minutes(to   date: Date) -> Int { Calendar.shared.dateComponents([.minute],      from: self, to: date).minute      ?? 0 }
    func seconds(to   date: Date) -> Int { Calendar.shared.dateComponents([.second],      from: self, to: date).second      ?? 0 }
    
    // MARK: - Временная зона
    
    func to(timeZone: TimeZone?) -> Date {
        guard let timeZone = timeZone else {
            #if DEBUG
            abort()
            #else
            return self
            #endif
        }
        
        let foreign = TimeInterval(timeZone.secondsFromGMT(for: self))
        let local   = TimeInterval(Calendar.shared.timeZone.secondsFromGMT(for: self))
        return self.addingTimeInterval(local - foreign)
    }
    
    func from(timeZone: TimeZone?) -> Date {
        guard let timeZone = timeZone else {
            #if DEBUG
            abort()
            #else
            return self
            #endif
        }
        
        let foreign = TimeInterval(timeZone.secondsFromGMT(for: self))
        let local   = TimeInterval(Calendar.shared.timeZone.secondsFromGMT(for: self))
        return self.addingTimeInterval(foreign - local)
    }
    
    // MARK: - Создание
    
    init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        let date = Calendar.shared.date(from: components)!
        self.init(timeInterval: 0, since: date)
    }
    
    init(year: Int, month: Int, day: Int) {
        self.init(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
    }
    
    // MARK: - Дебаг
    
    #if DEBUG
    var localizedString: String {
        return ISO8601DateFormatter.string(from: self, timeZone: TimeZone.current, formatOptions: [.withInternetDateTime])
    }
    #endif
}
