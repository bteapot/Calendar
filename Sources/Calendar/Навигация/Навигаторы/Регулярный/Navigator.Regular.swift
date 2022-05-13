//
//  Navigator.Regular.swift
//  Calendar
//
//  Created by Денис Либит on 27.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa


extension CalendarVC.Navigator {
    final class Regular: NSObject, NavigatorProtocol {
        
        // MARK: - Инициализация
        
        required init(
            vc:      UIViewController,
            info:    CalendarVC.Info,
            initial: CalendarVC.Section.Kind
        ) {
            // параметры
            self.vc = vc
            self.initial = initial
            self.info = info
            
            // инициализируемся
            super.init()
        }
        
        // MARK: - Свойства
        
        private weak var vc: UIViewController?
        
        private let info:    CalendarVC.Info
        private let initial: CalendarVC.Section.Kind
        
        private var binding = Lifetime.make()
        
        // MARK: - Протокол Navigator
        
        func viewDidLoad() {
            guard let vc = self.vc else {
                return
            }
            
            // зацепим интеракцию
            self.info.interaction.shown.output
                .observeValues { [weak self] section, date in
                    guard let self = self else { return }
                    self.set(date: date, sender: section)
                }
            
            self.info.interaction.tapped.output
                .observeValues { [weak self] section, date in
                    guard let self = self else { return }
                    
                    switch section.kind {
                    case .day:
                        break
                    case .week:
                        break
                    case .month:
                        break
                    case .year:
                        self.set(date: date, sender: section)
                        self.set(sectionOfKind: .day)
                    }
                }
            
            self.info.interaction.today.output
                .observeValues { [weak self] in
                    guard let self = self else { return }
                    self.set(date: Date(), sender: nil)
                }
            
            // добавим сабвьюхи
            vc.view.addSubview(self.toolbar)
            
            // ставим секцию
            self.set(section: self.current)
            
        }
        
        func layoutSubviews() {
            guard let vc = self.vc else {
                return
            }
            
            let bounds:         CGRect  = vc.view.bounds
            let insetted:       CGRect  = bounds.inset(by: vc.view.safeAreaInsets)
            let toolbarHeight:  CGFloat = self.toolbar.sizeThatFits(bounds.size).height.ceiled()
            
            // тулбар
            self.toolbar.frame =
                CGRect(
                    x:      0,
                    y:      0,
                    width:  bounds.width,
                    height: insetted.minY + toolbarHeight
                )
                .ceiled()
            
            // секция
            self.current.view.frame = bounds
            self.current.additionalSafeAreaInsets = .init(top: toolbarHeight)
        }
        
        func traitsChanged() {
            
        }
        
        func reload() {
            self.sections.forEach { $0.reload() }
            self.toolbar.update(period: self.current.display.value)
        }
        
        func update() {
            self.sections.forEach { $0.update() }
            self.toolbar.update(period: self.current.display.value)
        }
        
        func set(hidden: Bool, animated: Bool) {
            UIView.animate(withDuration: animated ? 0.25 : 0) {
                self.toolbar.alpha      = hidden ? 0 : 1
                self.current.view.alpha = hidden ? 0 : 1
            }
        }
        
        // MARK: - Тулбар
        
        private lazy var toolbar: Toolbar = {
            let toolbar =
                Toolbar(
                    sectionTitles: self.sections.map(\.kind.title),
                    selectedIndex: self.sections.firstIndex(where: { $0.kind == self.initial }) ?? -1,
                    info:          self.info,
                    delegate:      self
                )
            
            // следим за переключателем секций
            toolbar.switcher.reactive.selectedSegmentIndexes
                .observeValues { [weak self] index in
                    guard let self = self else { return }
                    self.set(section: self.sections[index])
                }
            
            // следим за кнопкой "сегодня"
            toolbar.today.reactive.pressed =
                CocoaAction(
                    Action<Void, Never, Never> { [weak self] in
                        SignalProducer { observer, lifetime in
                            guard let self = self else { return }
                            self.set(date: Date(), sender: nil)
                            observer.sendCompleted()
                        }
                    }
                )
            
            return toolbar
        }()
        
        // MARK: - Секции
        
        private lazy var sections: [RegularSectionProtocol] = [
            CalendarVC.Section.Regular.DayVC(self.info),
            CalendarVC.Section.Regular.WeekVC(self.info),
            CalendarVC.Section.Regular.MonthVC(self.info),
            CalendarVC.Section.Shared.YearVC(self.info),
        ]
        
        private lazy var current: RegularSectionProtocol = {
            if let index = self.sections.firstIndex(where: { $0.kind == self.initial }) {
                return self.sections[index]
            } else {
                return sections[0]
            }
        }()
        
        private func set(section: RegularSectionProtocol) {
            guard let vc = self.vc else {
                return
            }
            
            // отменим прошлые подписки
            self.binding = Lifetime.make()
            
            // убираем старую?
            if self.current !== section {
                self.current.willMove(toParent: nil)
                self.current.view.removeFromSuperview()
                self.current.removeFromParent()
            }
            
            // ставим новую
            vc.addChild(section)
            vc.view.insertSubview(section.view, at: 0)
            section.didMove(toParent: vc)
            
            // запомним
            self.current = section
            
            // тулбар
            self.toolbar.ruler = section.ruler
            
            // начинаем следить за меткой даты
            section.display
                .producer
                .take(during: self.binding.lifetime)
                .skipRepeats { $0.0 == $1.0 && $0.1 == $1.1 }
                .startWithValues { [toolbar=self.toolbar] string in
                    toolbar.update(period: string)
                }
            
            // скомандуем перевёрстку
            vc.view.setNeedsLayout()
        }
        
        fileprivate func set(sectionOfKind: CalendarVC.Section.Kind) {
            if let index = self.sections.firstIndex(where: { $0.kind == sectionOfKind }) {
                self.set(section: self.sections[index])
                self.toolbar.switcher.selectedSegmentIndex = index
            }
        }
        
        // MARK: - Дата
        
        fileprivate func set(
            date:   Date,
            sender: SectionProtocol?
        ) {
            // без изменений?
            guard date.isEqual(to: self.info.date, precision: .day) == false else {
                return
            }
            
            // запомним
            self.info.date =
                date.startOfDay
            
            // обновим все разделы кроме автора послания
            self.sections
                .filter { $0 !== sender }
                .forEach { section in
                    section.scroll(
                        to: self.info.date,
                        animated: true
                    )
                }
        }
        
    }
}

// MARK: - Делегат тулбара

extension CalendarVC.Navigator.Regular: UIToolbarDelegate {
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        guard let bar = bar as? UIToolbar else {
            return .any
        }
        
        switch bar {
        case self.toolbar: return .top
        default:           return .any
        }
    }
}
