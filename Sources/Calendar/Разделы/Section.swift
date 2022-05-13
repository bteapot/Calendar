//
//  Section.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


// MARK: - Протокол Section

protocol SectionProtocol where Self: UIViewController {
    var kind: CalendarVC.Section.Kind { get }
    var info: CalendarVC.Info { get }
    
    func reload()
    func update()
    
    func scroll(to date: Date, animated: Bool)
}

protocol RegularSectionProtocol: SectionProtocol {
    var display: Property<(Date?, Bool)> { get }
    var ruler: CalendarVC.Navigator.Ruler? { get }
}

// MARK: - Группировка

extension CalendarVC {
    public struct Section {}
}

extension CalendarVC.Section {
    public struct Regular {}
    public struct Compact {}
    public struct Shared {}
}

// MARK: - Тип секции

extension CalendarVC.Section {
    public enum Kind: Int {
        case day
        case week
        case month
        case year
    }
}

extension CalendarVC.Section.Kind: Comparable {
    public static func < (lhs: CalendarVC.Section.Kind, rhs: CalendarVC.Section.Kind) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension CalendarVC.Section.Kind {
    var title: String {
        switch self {
        case .day:   return NSLocalizedString("День",   comment: "Заголовок секции календаря.")
        case .week:  return NSLocalizedString("Неделя", comment: "Заголовок секции календаря.")
        case .month: return NSLocalizedString("Месяц",  comment: "Заголовок секции календаря.")
        case .year:  return NSLocalizedString("Год",    comment: "Заголовок секции календаря.")
        }
    }
}
