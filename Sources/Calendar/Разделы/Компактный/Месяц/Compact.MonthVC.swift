//
//  Compact.MonthVC.swift
//  AUS
//
//  Created by Денис Либит on 28.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa
import InfiniteScrollView


extension CalendarVC.Section.Compact {
    final class MonthVC: UIViewController, SectionProtocol {
        
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
                                
                                // поставим текущий день
                                self.info.interaction.today.input.send(value: ())
                                
                                // всё
                                observer.sendCompleted()
                            }
                        }
                    )
                return button
            }()
            
            // поставим данные
            self.update()
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Протокол Section
        
        var kind: CalendarVC.Section.Kind = .month
        let info: CalendarVC.Info
        
        func reload() {
            self.scrollView.reset()
            self.updateTitle()
            self.toolbar.update()
        }
        
        func update() {
            self.scrollView.items
                .compactMap { $0.view as? MonthView }
                .forEach {
                    $0.update()
                }
            
            self.updateTitle()
            self.toolbar.update()
        }
        
        func scroll(to date: Date, animated: Bool) {
            self.scrollView.scroll(
                to: date.months(from: self.info.zero),
                animated: animated
            )
            
            self.updateTitle()
        }
        
        // MARK: - Вьюхи
        
        private lazy var scrollView: InfiniteScrollView = {
            let scrollView =
                InfiniteScrollView(
                    frame: UIScreen.main.bounds,
                    direction: .vertical,
                    dataSource: self
                )
            return scrollView
        }()
        
        private lazy var toolbar =
            Toolbar(info: self.info)
        
        // MARK: - Жизненный цикл
        
        override func viewDidLoad() {
            self.view.backgroundColor = self.info.style.colors.background
            
            // добавим сабвьюхи
            self.view.addSubview(self.scrollView)
            self.view.addSubview(self.toolbar)
        }
        
        // MARK: - Геометрия
        
        private var freezeLayout: Bool = false
        
        override func viewWillLayoutSubviews() {
            guard self.freezeLayout == false else {
                return
            }
            
            let bounds:     CGRect  = self.view.bounds
            let insetted:   CGRect  = bounds.inset(by: self.view.safeAreaInsets)
            
            self.toolbar.frame =
                CGRect(
                    x:      0,
                    y:      0,
                    width:  bounds.width,
                    height: insetted.minY + self.toolbar.sizeThatFits(width: bounds.width).height
                )
            
            self.scrollView.frame = bounds
            self.scrollView.contentInset =
                UIEdgeInsets(top: self.toolbar.frame.height)
        }
        
        // MARK: - Оформление
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.update()
        }
        
        // MARK: - Инструменты
        
        private func updateTitle() {
            self.title = self.info.formatters.monthShort.string(from: self.info.date).capitalized
        }
    }
}

// MARK: - Источник данных InfiniteScrollView

extension CalendarVC.Section.Compact.MonthVC: InfiniteScrollViewDataSource {
    func initialIndex(isv: InfiniteScrollView) -> Int {
        return self.info.date.startOfMonth.months(from: self.info.zero)
    }
    
    func view(isv: InfiniteScrollView, index: Int) -> InfiniteScrollView.Info {
        return .init(
            view: MonthView(
                info:   self.info,
                date:   self.info.zero.adding(.month, value: index) ?? Date()
            ),
            length: .auto
        )
    }
    
    func shown(isv: InfiniteScrollView, view: UIView, index: Int) {
        let daysShift = self.info.date.days(from: self.info.date.startOfMonth)
        
        guard
            let view = view as? MonthView,
            let date = view.date.adding(.day, value: daysShift)
        else {
            return
        }
        
        // сообщим
        self.info.interaction.shown.input.send(value: (self, date))
        
        // обновим заголовок
        self.updateTitle()
    }
    
    func tap(isv: InfiniteScrollView, view: UIView, index: Int, point: CGPoint) {
        guard
            let view = view as? MonthView,
            let date = view.date(at: point)
        else {
            return
        }
        
        // сообщим
        self.info.interaction.tapped.input.send(value: (self, date))
        
        // обновим заголовок
        self.updateTitle()
    }
}

// MARK: - Анимации перехода

extension CalendarVC.Section.Compact.MonthVC {
    func view(for date: Date) -> MonthView? {
        return self.scrollView.items
            .compactMap({ $0.view as? MonthView })
            .first(where: { $0.date.isEqual(to: date, precision: .month) })
    }
    
    func toolbarHeight() -> CGFloat {
        return self.toolbar.frame.height
    }
    
    func layout(with yearVC: CalendarVC.Section.Shared.YearVC) -> CalendarVC.Navigator.Compact.Animations.Layout {
        // дата
        let date = self.info.date
        
        // целевые вьюхи года и месяца
        guard
            let yearView = yearVC.view(for: date),
            let monthView = self.view(for: date)
        else {
            return .empty
        }
        
        // остановим прокрутку
        self.scrollView.setContentOffset(self.scrollView.contentOffset, animated: false)
        
        // получим вьюхи нецелевых месяцев
        let otherMonthViews =
            self.scrollView.items
                .compactMap { $0.view as? CalendarVC.Section.Compact.MonthVC.MonthView }
                .filter { $0.date.isEqual(to: date, precision: .month) == false }
        
        // запомним оригинальные координаты вьюх нецелевых месяцев
        let otherMonthViewsData =
            otherMonthViews.map { view in (view, view.frame) }
        
        // получим блоки вёрстки вьюхи целевого месяца
        let viewLayout = monthView.layout(with: yearView)
        
        // вернём блоки вёрстки
        return .init(
            native: .init(
                prepare: {
                    // покажем тулбар
                    self.toolbar.alpha = 1
                    
                    // подготовим вьюху
                    viewLayout.native.prepare()
                },
                layout: {
                    // вернём оригинальный фон
                    self.view.backgroundColor = self.info.style.colors.background
                    
                    // покажем дни недели
                    self.toolbar.weekdayRuler.alpha = 1
                    
                    // вернём на место вьюхи нецелевых месяцев
                    otherMonthViewsData.forEach { view, frame in
                        view.frame = frame
                        view.alpha = 1
                    }
                    
                    // разрешим вёрстку
                    self.freezeLayout = false
                    
                    // переверстаем
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    
                    // выполним вёрстку вьюхи
                    viewLayout.native.layout()
                },
                cleanup: { success in
                    // выполним подчистку вьюхи
                    viewLayout.native.cleanup(success)
                }
            ),
            foreign: .init(
                prepare: {
                    // подготовим вьюху
                    viewLayout.foreign.prepare()
                },
                layout: {
                    // отключим вёрстку
                    self.freezeLayout = true
                    
                    // сделаем вьюху прозрачной
                    self.view.backgroundColor = .clear
                    
                    // подвинем тулбар
                    self.toolbar.frame.origin.y -=
                        self.toolbar.frame.height - self.view.safeAreaInsets.top
                    
                    // скроем дни недели
                    self.toolbar.weekdayRuler.alpha = 0
                    
                    // расставим вьюхи нецелевых месяцев
                    otherMonthViews.forEach { view in
                        // убираем вверх?
                        if view.frame.minY < monthView.frame.minY {
                            // вверх
                            view.frame.origin.y = self.scrollView.bounds.minY - view.frame.height
                        } else {
                            // вниз
                            view.frame.origin.y = self.scrollView.bounds.maxY
                        }
                        
                        // скроем
                        view.alpha = 0
                    }
                    
                    // выполним вёрстку вьюхи
                    viewLayout.foreign.layout()
                },
                cleanup: { success in
                    // скроем тулбар
                    self.toolbar.alpha = 0
                    
                    // включим вёрстку
                    self.freezeLayout = false
                    
                    // выполним подчистку вьюхи
                    viewLayout.foreign.cleanup(success)
                }
            )
        )
    }
    
    func layout(with dayVC: CalendarVC.Section.Compact.DayVC) -> CalendarVC.Navigator.Compact.Animations.Layout {
        // дата
        let date = self.info.date
        
        // целевые вьюхи года и месяца
        guard
            let rulerView = dayVC.rulerView(),
            let monthView = self.view(for: date)
        else {
            return .empty
        }
        
        // остановим прокрутку
        self.scrollView.setContentOffset(self.scrollView.contentOffset, animated: false)
        
        // высота тулбара контроллера дня
        let dayVCToolbarHeight: CGFloat =
            dayVC.toolbarHeight()
        
        // данные временных слоёв анимации между слоями дней контроллеров месяца и дня
        let temporaryDayLayers: [(layer: MonthView.DayLayer, native: CGPoint, foreign: CGPoint)] =
            rulerView.elements
                .compactMap { weekdayLayer in
                    // временный слой
                    let layer =
                        MonthView.DayLayer(
                            info: self.info,
                            date: weekdayLayer.date
                        )
                    
                    // родной слой вьюхи месяца
                    guard let dayLayer = monthView.dayLayer(for: weekdayLayer.date) else {
                        return nil
                    }
                    
                    // поставим параметры из слоя месяца
                    layer.bounds.size = dayLayer.bounds.size
                    layer.events = dayLayer.events
                    layer.update()
                    
                    // положение дня во вьюхе месяца
                    let native: CGPoint =
                        self.view.layer.convert(dayLayer.position, from: monthView.layer)
                    
                    // положение слоя дня в рулере
                    let foreign: CGPoint =
                        self.view.layer.convert(weekdayLayer.position, from: weekdayLayer.superlayer)

                    return (
                        layer:   layer,
                        native:  native,
                        foreign: foreign
                    )
                }
        
        // вычислим величины сдвигов вверх и вниз
        guard
            let monthViewWeekPoint: CGPoint = monthView.point(for: date),
            let weekdayLayer = rulerView.elements.first
        else {
            return .empty
        }

        let targetY: CGFloat =
            self.view.layer.convert(monthViewWeekPoint, from: monthView.layer).y
        
        let rulerY: CGFloat =
            self.view.layer.convert(weekdayLayer.position, from: weekdayLayer.superlayer).y
        
        let deltaUp:   CGFloat = targetY - rulerY
        let deltaDown: CGFloat = self.view.bounds.maxY - targetY
        
        // получим вьюхи нецелевых месяцев
        let otherMonthViews =
            self.scrollView.items
                .compactMap { $0.view as? CalendarVC.Section.Compact.MonthVC.MonthView }
                .filter { $0.date.isEqual(to: date, precision: .month) == false }
        
        // запомним оригинальные координаты вьюх нецелевых месяцев
        let otherMonthViewsData =
            otherMonthViews.map { view in (view, view.frame) }
        
        // получим блоки вёрстки вьюхи целевого месяца
        let viewLayout =
            monthView.layout(
                dayVC:     dayVC,
                targetY:   monthViewWeekPoint.y,
                deltaUp:   deltaUp,
                deltaDown: deltaDown
            )
        
        // вернём блоки вёрстки
        return .init(
            native: .init(
                prepare: {
                    // подготовим вьюху
                    viewLayout.native.prepare()
                },
                layout: {
                    // подвинем слои дней из тулбара в сетку месяца
                    temporaryDayLayers.forEach { layer, native, foreign in
                        layer.position = native
                        layer.update(transitioning: .native)
                    }
                    
                    // вернём на место вьюхи нецелевых месяцев
                    otherMonthViewsData.forEach { view, frame in
                        view.frame = frame
                        view.alpha = 1
                    }
                    
                    // разрешим вёрстку
                    self.freezeLayout = false
                    
                    // переверстаем
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    
                    // выполним вёрстку вьюхи
                    viewLayout.native.layout()
                },
                cleanup: { success in
                    // вернём оригинальный фон
                    self.view.backgroundColor = self.info.style.colors.background
                    
                    // выполним подчистку вьюхи
                    viewLayout.native.cleanup(success)
                    
                    // уберём временные слои
                    temporaryDayLayers.forEach { layer, native, foreign in
                        layer.removeFromSuperlayer()
                    }
                }
            ),
            foreign: .init(
                prepare: {
                    // поставим прозрачный фон
                    self.view.backgroundColor = .clear
                    
                    // поставим слои дней
                    temporaryDayLayers.forEach { layer, native, foreign in
                        layer.position = native
                        self.view.layer.addSublayer(layer)
                        layer.layoutIfNeeded()
                    }
                    
                    // подготовим вьюху
                    viewLayout.foreign.prepare()
                },
                layout: {
                    // отключим вёрстку
                    self.freezeLayout = true
                    
                    // поставим тулбар в размер тулбара контроллера дня
                    self.toolbar.frame.size.height = dayVCToolbarHeight
                    self.toolbar.layoutIfNeeded()
                    
                    // подвинем слои дней в тулбар
                    temporaryDayLayers
                        .forEach { layer, native, foreign in
                            layer.position = foreign + (layer.bounds.center - layer.textLayer.position)
                            layer.update(transitioning: .foreign)
                        }
                    
                    // расставим вьюхи нецелевых месяцев
                    otherMonthViews.forEach { view in
                        // убираем вверх?
                        if view.frame.minY < monthView.frame.minY {
                            // вверх
                            view.frame.origin.y -= deltaUp
                        } else {
                            // вниз
                            view.frame.origin.y += deltaDown
                        }
                        
                        // скроем
                        view.alpha = 0
                    }
                    
                    // выполним вёрстку вьюхи
                    viewLayout.foreign.layout()
                },
                cleanup: { success in
                    // вернём оригинальный фон
                    self.view.backgroundColor = self.info.style.colors.background
                    
                    // уберём временные слои
                    temporaryDayLayers.forEach { layer, native, foreign in
                        layer.removeFromSuperlayer()
                    }
                    
                    // разрешим вёрстку
                    self.freezeLayout = false
                    
                    // переверстаем
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    
                    if success {
                        // юзер мог тапнуть не по отцентрованному месяцу
                        self.reload()
                    } else {
                        // вернём на место вьюхи нецелевых месяцев
                        otherMonthViewsData.forEach { view, frame in
                            view.frame = frame
                            view.alpha = 1
                        }
                        
                        // выполним подчистку вьюхи
                        viewLayout.foreign.cleanup(success)
                    }
                }
            )
        )
    }
}
