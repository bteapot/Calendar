//
//  EKEventWrapper.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit
import EventKit
import Calendar


extension CalendarVC.DataSource.EventKit {
    public struct EventWrapper {
        public let ekEvent: EKEvent
    }
}

extension CalendarVC.DataSource.EventKit.EventWrapper: CalendarEventProtocol {
    public var title: String {
        get { self.ekEvent.title }
        set { self.ekEvent.title = newValue }
    }
    
    public var location: String? {
        get { self.ekEvent.location }
        set { self.ekEvent.location = newValue }
    }
    
    public var creationDate: Date? {
        self.ekEvent.creationDate
    }
    
    public var lastModifiedDate: Date? {
        self.ekEvent.lastModifiedDate
    }
    
    public var timeZone: TimeZone? {
        get { self.ekEvent.timeZone }
        set { self.ekEvent.timeZone = newValue }
    }
    
    public var url: URL? {
        get { self.ekEvent.url }
        set { self.ekEvent.url = newValue }
    }
    
    public var interval: DateInterval {
        get { DateInterval(start: self.ekEvent.startDate, end: self.ekEvent.endDate) }
        set {
            self.ekEvent.startDate = newValue.start
            self.ekEvent.endDate   = newValue.end
        }
    }
    
    public var isAllDay: Bool {
        get { self.ekEvent.isAllDay }
        set { self.ekEvent.isAllDay = newValue }
    }
    
    public var color: CGColor {
        self.ekEvent.calendar?.cgColor ?? UIColor.systemRed.cgColor
    }
    
    public var isReadonly: Bool {
        self.ekEvent.calendar?.allowsContentModifications ?? true
    }
    
    public func isEqual(to other: CalendarEventProtocol) -> Bool {
        if let other = other as? CalendarVC.DataSource.EventKit.EventWrapper {
            return self.ekEvent.eventIdentifier == other.ekEvent.eventIdentifier
        } else {
            return false
        }
    }
}
