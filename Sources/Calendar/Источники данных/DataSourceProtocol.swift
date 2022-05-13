//
//  DataSourceProtocol.swift
//  Calendar
//
//  Created by Денис Либит on 15.04.2021.
//

import Foundation
import UIKit
import ReactiveSwift


// MARK: - Источник данных

public protocol DataSourceProtocol {
    var state:   Property<CalendarVC.DataSource.State> { get }
    var changes: Signal<Void, Never> { get }
    var errors:  Signal<Error, Never> { get }
    
    func events(in interval: DateInterval) -> SignalProducer<[CalendarEventProtocol], Never>
    func save(event: CalendarEventProtocol) -> SignalProducer<Never, Never>
}

extension CalendarVC {
    public struct DataSource {}
}

// MARK: - Состояние источника данных

extension CalendarVC.DataSource {
    public enum State {
        case undetermined
        case ready
        case placeholder(UIViewController)
    }
}

extension CalendarVC.DataSource.State: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.undetermined, .undetermined): return true
        case (.ready,        .ready):        return true
        default:                             return false
        }
    }
}

extension CalendarVC.DataSource.State {
    public var isReady: Bool {
        switch self {
        case .undetermined: return false
        case .ready:        return true
        case .placeholder:  return false
        }
    }
}
