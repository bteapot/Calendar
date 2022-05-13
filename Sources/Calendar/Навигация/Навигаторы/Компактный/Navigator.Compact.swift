//
//  Navigator.Compact.swift
//  Calendar
//
//  Created by Денис Либит on 27.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa


extension CalendarVC.Navigator {
    final class Compact: NSObject, NavigatorProtocol {
        
        typealias MonthVC = CalendarVC.Section.Compact.MonthVC
        typealias DayVC   = CalendarVC.Section.Compact.DayVC
        
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
        
        deinit {
            // отцепимся от nc
            self.nc?.delegate = nil
            self.nc?.interactivePopGestureRecognizer?.delegate = nil
        }
        
        // MARK: - Свойства
        
        private weak var vc: UIViewController?
        private weak var nc: UINavigationController?
        
        private let info:    CalendarVC.Info
        private let initial: CalendarVC.Section.Kind
        
        // MARK: - Протокол Navigator
        
        func viewDidLoad() {
            guard
                let vc = self.vc,
                let nc = vc.navigationController
            else {
                return
            }
            
            // зацепим nc
            self.nc = nc
            nc.delegate = self
            nc.interactivePopGestureRecognizer?.delegate = self
            
            // фиксируем оригинальный заголовок
            vc.navigationItem.titleView = {
                let label = UILabel(frame: .zero)
                label.text = vc.title
                label.adjustsFontForContentSizeCategory = true
                return label
            }()
            self.updateTitle()
            
            // кнопки навбара
            vc.navigationItem.reactive.rightBarButtonItem <~
                self.info.dataSource.state
                    .producer
                    .map { state -> UIBarButtonItem? in
                        switch state {
                            case .undetermined:
                                return nil
                                
                            case .ready:
                                let button = UIBarButtonItem(title: "Сегодня", style: .plain, target: nil, action: nil)
                                button.reactive.pressed =
                                    CocoaAction(
                                        Action<Void, Void, Never> { [weak self] in
                                            SignalProducer { observer, lifetime in
                                                guard let self = self else { return }
                                                
                                                // поставим текущий день
                                                self.info.interaction.today.input.send(value: ())
                                                
                                                // всё
                                                observer.sendCompleted()
                                            }
                                        }
                                    )
                                return button
                                
                            case .placeholder:
                                return nil
                        }
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
                    
                    self.set(date: date, sender: section)
                    
                    switch section.kind {
                    case .day, .week:
                        break
                    case .month:
                        self.push(
                            section: DayVC(self.info),
                            animated: true
                        )
                    case .year:
                        self.push(
                            section: MonthVC(self.info),
                            animated: true
                        )
                    }
                }
            
            self.info.interaction.today.output
                .observeValues { [weak self] in
                    guard let self = self else { return }
                    self.set(date: Date(), sender: nil)
                }
            
            // пробрасываем данные navigationItem корневой секции
            vc.navigationItem.reactive.title <~
                self.yearSection.navigationItem.reactive.producer(for: \.title)
            
            // подготовим начальный стэк секций
            let (additional, mask) = { () -> ([UIViewController], UIViewController?) in
                // источник данных не готов?
                if self.info.dataSource.state.value != .ready {
                    return ([], nil)
                }
                
                // источник готов, соберём стэк
                switch self.initial {
                case .day: return (
                    [MonthVC(self.info), DayVC(self.info)],
                    DayVC(self.info)
                )
                case .month:return (
                    [MonthVC(self.info)],
                    DayVC(self.info)
                )
                case .year, .week:
                    return ([], nil)
                }
            }()
            
            // пляски с пушем множественных контроллеров
            if let mask = mask {
                // имитируем пуш последней секции
                vc.addChild(mask)
                mask.view.frame = vc.view.bounds
                mask.view.isUserInteractionEnabled = false
                vc.view.insertSubview(mask.view, at: 0)
                mask.didMove(toParent: vc)
                
                // ставим полный стэк контроллеров
                additional.forEach { nc.pushViewController($0, animated: false) }
                
                // по появлению последнего убираем маску
                additional.last?.reactive
                    .trigger(for: #selector(UIViewController.viewDidAppear))
                    .take(first: 1)
                    .take(during: vc.reactive.lifetime)
                    .observeValues { [weak self, weak vc] in
                        guard
                            let self = self,
                            let vc = vc
                        else {
                            return
                        }
                        
                        // уберём маску
                        mask.willMove(toParent: nil)
                        mask.view.removeFromSuperview()
                        mask.removeFromParent()
                        
                        // поставим корневую секцию
                        vc.addChild(self.yearSection)
                        self.yearSection.view.frame = vc.view.bounds
                        vc.view.insertSubview(self.yearSection.view, at: 0)
                        self.yearSection.didMove(toParent: vc)
                    }
            } else {
                // дополнительных нет, просто ставим секцию года
                vc.addChild(self.yearSection)
                vc.view.insertSubview(self.yearSection.view, at: 0)
                self.yearSection.didMove(toParent: vc)
            }
        }
        
        func layoutSubviews() {
            guard let vc = self.vc else {
                return
            }
            
            let bounds: CGRect  = vc.view.bounds
            
            // корневая
            vc.children.first?.view.frame = bounds
        }
        
        func traitsChanged() {
            self.updateTitle()
        }
        
        func reload() {
            self.sections().forEach { $0.reload() }
//            self.toolbar.update(for: self.current.kind)
        }
        
        func update() {
            self.sections().forEach { $0.update() }
//            self.toolbar.update(for: self.current.kind)
        }
        
        func set(hidden: Bool, animated: Bool) {
            UIView.animate(withDuration: animated ? 0.25 : 0) {
                self.yearSection.view.alpha = hidden ? 0 : 1
            }
        }
        
        // MARK: - Секции
        
        private lazy var yearSection =
            CalendarVC.Section.Shared.YearVC(self.info)
        
        private func push(section: SectionProtocol, animated: Bool) {
            guard let nc = self.nc else {
                return
            }
            
            // пихаем в стэк
            nc.pushViewController(section, animated: animated)
        }
        
        // MARK: - Дата
        
        fileprivate func set(
            date:   Date,
            sender: SectionProtocol?
        ) {
            guard let nc = self.nc else {
                return
            }
            
            // это кнопка "сегодня" или дата изменилась?
            guard
                sender == nil ||
                date.isEqual(to: self.info.date, precision: .day) == false
            else {
                return
            }
            
            // запомним
            self.info.date =
                date.startOfDay
            
            // обновим все разделы кроме автора послания
            nc.viewControllers
                .compactMap { (vc: UIViewController) -> SectionProtocol? in
                    // корневой?
                    if vc === self.vc {
                        return self.yearSection
                    }
                    
                    // что-то другое
                    return vc as? SectionProtocol
                }
                .filter { $0 !== sender }
                .forEach { section in
                    section.scroll(
                        to: self.info.date,
                        animated: true
                    )
                }
        }
        
        // MARK: - Инструменты
        
        private func updateTitle() {
            guard
                let vc = self.vc,
                let nc = self.nc,
                let label = vc.navigationItem.titleView as? UILabel,
                let string = label.attributedText?.mutableCopy() as? NSMutableAttributedString
            else {
                return
            }
            
            string.setAttributes(
                nc.navigationBar.standardAppearance.titleTextAttributes,
                range: NSRange(location: 0, length: string.length)
            )
            label.attributedText = string
            label.sizeToFit()
        }
        
        private func sections() -> [SectionProtocol] {
            return [self.yearSection] + (self.nc?.viewControllers.compactMap({ $0 as? SectionProtocol }) ?? [])
        }
    }
}

// MARK: - Делегат UINavigationController

extension CalendarVC.Navigator.Compact: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch (fromVC, toVC) {
        case (is CalendarVC, is MonthVC):    return Animations.YM(info: self.info)
        case (is MonthVC,    is CalendarVC): return Animations.MY(info: self.info)
        case (is MonthVC,    is DayVC):      return Animations.MD(info: self.info)
        case (is DayVC,      is MonthVC):    return Animations.DM(info: self.info)
        default:
            return nil
        }
    }
}

// MARK: - Делегат UIGestureRecognizer

extension CalendarVC.Navigator.Compact: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // отключим back swipe для контроллеров дня и месяца
        guard
            let nc = self.nc,
            gestureRecognizer === nc.interactivePopGestureRecognizer,
            let topVC = nc.topViewController
        else {
            // не наш случай
            return true
        }
        
        switch topVC {
        case is MonthVC, is DayVC:
            // для этих отключаем back swipe
            return false
        default:
            // ладно, пускай
            return true
        }
    }
}
