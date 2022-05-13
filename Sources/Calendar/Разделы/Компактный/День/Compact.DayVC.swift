//
//  Compact.DayVC.swift
//  Calendar
//
//  Created by Денис Либит on 28.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa
import InfiniteScrollView


extension CalendarVC.Section.Compact {
    final class DayVC: UIViewController, SectionProtocol {
        
        // MARK: - Инициализация
        
        required init(_ info: CalendarVC.Info) {
            // параметры
            self.info = info
            
            // инициализируемся
            super.init(nibName: nil, bundle: nil)
            
            // настроим навбар
            self.navigationItem.setup()
            
            // глушим заголовок
            self.navigationItem.titleView = UIView()
            
            // кнопки навбара
            self.navigationItem.rightBarButtonItem = {
                let button = UIBarButtonItem(title: "Сегодня", style: .plain, target: nil, action: nil)
                button.reactive.pressed =
                    CocoaAction(
                        Action<Void, Void, Never> { [weak self] in
                            SignalProducer { observer, lifetime in
                                guard let self = self else { return }
                                
                                // подкрутим, если и так показан текущий день
                                if let view = self.daysScrollView.centered()?.view as? DayViewProtocol {
                                    view.scrollToNowIfToday(animated: true)
                                }
                                
                                // поставим текущий день
                                self.info.interaction.today.input.send(value: ())
                                
                                // всё
                                observer.sendCompleted()
                            }
                        }
                    )
                return button
            }()
            
            // поставим заголовок
            self.updateDate()
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Протокол Section
        
        var kind: CalendarVC.Section.Kind = .day
        let info: CalendarVC.Info
        
        func reload() {
            self.daysScrollView.reset()
            self.toolbar.scrollView.reset()
            self.updateDate()
        }
        
        func update() {
            self.daysScrollView.items
                .compactMap { $0.view as? DayViewProtocol }
                .forEach {
                    $0.update()
                }
            
            self.updateDate()
        }
        
        func scroll(to date: Date, animated: Bool) {
            self.daysScrollView.scroll(
                to: date.days(from: self.info.zero),
                animated: animated
            )
            
            self.toolbar.scrollView.scroll(
                to: date.weeks(from: self.info.zero),
                animated: true
            )
            
            self.updateDate()
        }
        
        // MARK: - Вьюхи
        
        private lazy var daysScrollView: InfiniteScrollView = {
            let scrollView =
                InfiniteScrollView(
                    frame: UIScreen.main.bounds,
                    direction: .horizontal,
                    dataSource: self,
                    taps: self.info.customization.dayView.standardSelection
                )
            scrollView.isPagingEnabled = true
            
            // rtl
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                scrollView.transform = CGAffineTransform(scaleX:-1, y: 1)
            }
            
            return scrollView
        }()
        
        private lazy var toolbar =
            Toolbar(
                info: self.info,
                dataSource: self
            )
        
        // MARK: - Сдвиг дней
        
        private let offsetSync = Signal<(DayViewProtocol, CGFloat), Never>.pipe()
        private var offset: CGFloat = 0
        
        // MARK: - Жизненный цикл
        
        override func viewDidLoad() {
            // свойства вьюхи
            self.view.backgroundColor = self.info.style.colors.background
            
            // добавим сабвьюхи
            self.view.addSubview(self.daysScrollView)
            self.view.addSubview(self.toolbar)
            
            // зацепим синхронизацию сдвига
            self.offsetSync.output
                .observeValues { [weak self] sender, offset in
                    guard let self = self else { return }
                    
                    // запомним для новых
                    self.offset = offset
                    
                    // подвинем старые
                    self.daysScrollView.items
                        .compactMap {
                            if  let view = $0.view as? DayViewProtocol,
                                view !== sender
                            {
                                return view
                            } else {
                                return nil
                            }
                        }
                        .forEach { (view: DayViewProtocol) in
                            view.set(offset: offset)
                        }
                }
            
            // раз в минуту обновляем
            SignalProducer
                .autopausedTimer(after: Date().start(of: .minute).addingTimeInterval(60), interval: 60, on: QueueScheduler.main)
                .take(during: self.reactive.lifetime)
                .startWithValues { [weak self] _ in
                    guard let self = self else { return }
                    self.update()
                }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            // снимем выделение
            self.info.selection.deselect()
        }
        
        // MARK: - Геометрия
        
        private var freezeLayout: Bool = false
        
        override func viewWillLayoutSubviews() {
            guard self.freezeLayout == false else {
                return
            }
            
            let bounds:         CGRect  = self.view.bounds
            let insetted:       CGRect  = bounds.inset(by: self.view.safeAreaInsets)
            let toolbarHeight:  CGFloat = self.toolbar.sizeThatFits(width: bounds.width).height
            
            self.toolbar.frame =
                CGRect(
                    x:      0,
                    y:      0,
                    width:  bounds.width,
                    height: insetted.minY + toolbarHeight
                )
            
            self.daysScrollView.frame = bounds
            self.daysScrollView.contentInset = UIEdgeInsets(top: toolbarHeight)
        }
        
        // MARK: - Оформление
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.update()
        }
        
        // MARK: - Инструменты
        
        private func updateDate() {
            // обновим рулер
            self.toolbar.scrollView.items
                .compactMap { $0.view as? CalendarVC.Section.Shared.RulerView<WeekdayLayer> }
                .flatMap { $0.elements }
                .forEach {
                    $0.update()
                }
            
            // обновим заголовок
            self.title =
                self.info.formatters.dayAndMonth.string(from: self.info.date).capitalized
            
            // обновим тулбар
            self.toolbar.update()
        }
    }
}

// MARK: - Источник данных InfiniteScrollView

extension CalendarVC.Section.Compact.DayVC: InfiniteScrollViewDataSource {
    func initialIndex(isv: InfiniteScrollView) -> Int {
        switch isv {
        case self.daysScrollView:
            // вьюха дня
            return self.info.date.startOfDay.days(from: self.info.zero)
            
        case self.toolbar.scrollView:
            // рулер дней недели
            return self.info.date.startOfWeek.weeks(from: self.info.zero.startOfWeek)
            
        default:
            return 0
        }
    }
    
    func view(isv: InfiniteScrollView, index: Int) -> InfiniteScrollView.Info {
        switch isv {
            case self.daysScrollView:
                // вьюха дня
                let view =
                    self.info.customization.dayView.init(
                        info:   self.info,
                        date:   self.info.zero.adding(.day, value: index) ?? Date(),
                        offset: self.offset,
                        input:  self.offsetSync.input
                    )
                
                // rtl
                if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                    view.transform = CGAffineTransform(scaleX: -1, y: 1)
                }

                return .init(
                    view: view,
                    length: .flexible(1)
                )
                
            case self.toolbar.scrollView:
                // рулер дней недели
                let startOfWeek: Date =
                self.info.zero.startOfWeek.adding(.weekOfMonth, value: index) ?? Date()
                
                return .init(
                    view: CalendarVC.Section.Shared.RulerView<WeekdayLayer>(
                        elements: Array(0..<self.info.metrics.daysInWeek)
                            .map { index in
                                WeekdayLayer(
                                    info: self.info,
                                    date: startOfWeek.adding(.day, value: index) ?? startOfWeek
                                )
                            },
                        height: 0
                    ),
                    length: .flexible(1)
                )
                
            default:
                return .init(view: UIView(), length: .auto)
        }
    }
    
    func shown(isv: InfiniteScrollView, view: UIView, index: Int) {
        switch isv {
        case self.daysScrollView:
            // вьюха дня
            guard
                let view = view as? DayViewProtocol
            else {
                return
            }
            
            // сообщим
            self.info.interaction.shown.input.send(value: (self, view.date))
            
            // обновим отображение даты
            self.updateDate()
            
            // открутим рулер
            self.toolbar.scrollView.scroll(
                to: view.date.weeks(from: self.info.zero),
                animated: true
            )
            
        case self.toolbar.scrollView:
            // рулер дней недели
            let daysShift = self.info.date.days(from: self.info.date.startOfWeek)
            
            guard
                let view = view as? CalendarVC.Section.Shared.RulerView<WeekdayLayer>,
                let date = view.elements.first?.date.adding(.day, value: daysShift)
            else {
                return
            }
            
            // сообщим
            self.info.interaction.shown.input.send(value: (self, date))
            
            // обновим отображение даты
            self.updateDate()
            
            // открутим крутилку дней
            self.daysScrollView.scroll(
                to: date.days(from: self.info.zero),
                animated: true
            )
            
        default:
            break
        }
    }
    
    func tap(isv: InfiniteScrollView, view: UIView, index: Int, point: CGPoint) {
        switch isv {
        case self.daysScrollView:
            // вьюха дня
            guard
                let view = view as? DayViewProtocol
            else {
                return
            }
            
            // тап по событию?
            let infos: [DayViewProtocol.EventInfo] = view.eventInfos(at: point)
            
            if infos.isEmpty == false {
                // событий несколько, уже что-то выбрано и выбранное есть среди событий в точке касания?
                if  infos.count > 1,
                    let selected = self.info.selection.event,
                    let index = infos.firstIndex(where: { $0.event.isEqual(to: selected) })
                {
                    let next: Int = infos.indices.contains(index + 1) ? index + 1 : 0
                    self.info.selection.select(infos[next])
                } else {
                    // выберем первое событие
                    self.info.selection.select(infos[0])
                }
            } else {
                self.info.selection.deselect()
            }
            
        case self.toolbar.scrollView:
            // рулер дней недели
            guard
                let view = view as? CalendarVC.Section.Shared.RulerView<WeekdayLayer>,
                let date = view.element(at: point)?.date
            else {
                return
            }
            
            // сообщим
            self.info.interaction.shown.input.send(value: (self, date))
            
            // обновим отображение даты
            self.updateDate()
            
            // открутим крутилку дней
            self.daysScrollView.scroll(
                to: date.days(from: self.info.zero),
                animated: true
            )
            
        default:
            break
        }
    }
}

// MARK: - Анимации перехода

extension CalendarVC.Section.Compact.DayVC {
    func view(for date: Date) -> DayViewProtocol? {
        return self.daysScrollView.items
            .compactMap({ $0.view as? DayViewProtocol })
            .first(where: { $0.date.isEqual(to: date, precision: .day) })
    }
    
    func rulerView() -> CalendarVC.Section.Shared.RulerView<WeekdayLayer>? {
        return self.toolbar.scrollView.centered()?.view as? CalendarVC.Section.Shared.RulerView<WeekdayLayer>
    }
    
    func toolbarHeight() -> CGFloat {
        return self.toolbar.frame.height
    }
    
    func layout(with monthVC: CalendarVC.Section.Compact.MonthVC) -> CalendarVC.Navigator.Compact.Animations.Layout {
        // дата
        let date = self.info.date
        
        // целевые вьюхи года и месяца
        guard
            let monthView = monthVC.view(for: date),
            let monthViewWeekPoint: CGPoint = monthView.point(for: date),
            let rulerView = self.rulerView(),
            let weekdayLayer = rulerView.elements.first
        else {
            return .empty
        }
        
        // остановим прокрутку
        self.daysScrollView.setContentOffset(self.daysScrollView.contentOffset, animated: false)
        self.toolbar.scrollView.setContentOffset(self.toolbar.scrollView.contentOffset, animated: false)
        
        // дни в рулере, не принадлежащие текущему месяцу
        let foreignDays: [WeekdayLayer] =
            rulerView.elements
                .filter { $0.date.isEqual(to: date, precision: .month) == false }
        
        // точка разделения вьюхи месяца
        let targetY: CGFloat =
            self.view.convert(monthViewWeekPoint, from: monthView).y
        
        // вычислим величины сдвигов вверх и вниз
        let rulerY: CGFloat =
            self.view.layer.convert(weekdayLayer.position, from: weekdayLayer.superlayer).y
        
        let deltaUp:   CGFloat = targetY - rulerY
        let deltaDown: CGFloat = self.view.bounds.maxY - targetY
        
        // маски скроллера дней
        let maskRects =
            self.daysScrollView.frame.divided(atDistance: targetY + monthView.maskShift(), from: .minYEdge)
        
        var maskUp:   UIView? = nil
        var maskDown: UIView? = nil
        
        // вернём блоки вёрстки
        return .init(
            native: .init(
                prepare: {
                    // спрячем чужие дни
                    foreignDays.forEach {
                        $0.opacity = 0
                    }
                    
                    // спрячем метку текущего дня
                    self.toolbar.periodLabel.alpha = 0
                },
                layout: {
                    // раздвинем маски на скроллере дней
                    maskUp?.frame.origin.y -= deltaUp
                    maskDown?.frame.origin.y += deltaDown
                    
                    // разрешим вёрстку
                    self.freezeLayout = false
                    
                    // переверстаем
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                },
                cleanup: { success in
                    // покажем тулбар
                    self.toolbar.isHidden = false
                    
                    // пост-анимация
                    UIView.animate(withDuration: 0.25) {
                        CATransaction.begin()
                        CATransaction.setAnimationDuration(0.25)
                        CATransaction.setDisableActions(false)
                        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .default))
                        
                        // покажем в тулбаре дни нецелевых месяцев
                        foreignDays.forEach {
                            $0.opacity = 1
                        }
                        
                        // покажем метку текущего дня
                        self.toolbar.periodLabel.alpha = 1
                    
                        CATransaction.commit()
                    }
                    
                    // уберём маски
                    maskUp?.removeFromSuperview()
                    maskDown?.removeFromSuperview()
                }
            ),
            foreign: .init(
                prepare: {
                    // отключим вёрстку
                    self.freezeLayout = true
                    
                    // спрячем тулбар
                    self.toolbar.isHidden = true
                    
                    // поставим маски на скроллер дней в преданимационное положение
                    maskUp = {
                        let mask = UIView(frame: maskRects.slice.offsetBy(dx: 0, dy: -deltaUp))
                        mask.backgroundColor = self.info.style.colors.background
                        self.view.insertSubview(mask, aboveSubview: self.daysScrollView)
                        return mask
                    }()
                    
                    maskDown = {
                        let mask = UIView(frame: maskRects.remainder.offsetBy(dx: 0, dy: deltaDown))
                        mask.backgroundColor = self.info.style.colors.background
                        self.view.insertSubview(mask, aboveSubview: self.daysScrollView)
                        return mask
                    }()
                },
                layout: {
                    // задвинем маски на скроллере дней
                    maskUp?.frame.origin.y += deltaUp
                    maskDown?.frame.origin.y -= deltaDown
                },
                cleanup: { success in
                    // разрешим вёрстку
                    self.freezeLayout = false
                    
                    // неуспешно?
                    if success == false {
                        // покажем тулбар
                        self.toolbar.isHidden = false
                        
                        // уберём маски
                        maskUp?.removeFromSuperview()
                        maskDown?.removeFromSuperview()
                        
                        // переверстаем
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                    }
                }
            )
        )
    }
}
