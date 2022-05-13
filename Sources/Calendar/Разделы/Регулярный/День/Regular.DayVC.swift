//
//  DayVC.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


extension CalendarVC.Section.Regular {
    final class DayVC: UIViewController, RegularSectionProtocol {
        
        // MARK: - Инициализация
        
        required init(_ info: CalendarVC.Info) {
            // параметры
            self.info = info
            
            // инициализируемся
            super.init(nibName: nil, bundle: nil)
            
            // настроим навбар
            self.navigationItem.setup()
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Протокол Section
        
        var kind: CalendarVC.Section.Kind = .day
        let info: CalendarVC.Info
        
        func reload() {
            self.daysScrollView.reset()
            self.rulerScrollView.reset()
        }
        
        func update() {
            self.daysScrollView.items
                .compactMap { $0.view as? DayViewProtocol }
                .forEach {
                    $0.update()
                }
            
            self.updateRuler()
        }
        
        func scroll(to date: Date, animated: Bool) {
            self.daysScrollView.scroll(
                to: date.days(from: self.info.zero),
                animated: animated
            )
            
            self.rulerScrollView.scroll(
                to: date.weeks(from: self.info.zero),
                animated: true
            )
        }
        
        lazy var display: Property<(Date?, Bool)> =
            Property(
                initial: self.info.date,
                then: self.info.interaction.shown.output.map(\.1)
            )
            .map { ($0, true) }
        
        lazy var ruler: CalendarVC.Navigator.Ruler? =
            CalendarVC.Navigator.Ruler(
                size: { width in
                    return CGSize(
                        width:  width,
                        height: RulerView.height(for: self.info)
                    )
                },
                view: self.rulerScrollView
            )
        
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
            return scrollView
        }()
        
        private lazy var rulerScrollView: InfiniteScrollView = {
            let scrollView =
                InfiniteScrollView(
                    frame: .zero,
                    direction: .horizontal,
                    dataSource: self
                )
            scrollView.isPagingEnabled = true
            return scrollView
        }()
        
        // MARK: - Сдвиг дней
        
        private let offsetSync = Signal<(DayViewProtocol, CGFloat), Never>.pipe()
        private var offset: CGFloat = 0
        
        // MARK: - Жизненный цикл
        
        override func loadView() {
            self.view = self.daysScrollView
        }
        
        override func viewDidLoad() {
            self.view.backgroundColor = self.info.style.colors.background
            
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
        
        // MARK: - Инструменты
        
        private func updateRuler() {
            self.rulerScrollView.items
                .forEach {
                    $0.view.setNeedsDisplay()
                }
        }
    }
}

// MARK: - Источник данных InfiniteScrollView

extension CalendarVC.Section.Regular.DayVC: InfiniteScrollViewDataSource {
    func initialIndex(isv: InfiniteScrollView) -> Int {
        switch isv {
        case self.daysScrollView:
            // вьюха дня
            return self.info.date.startOfDay.days(from: self.info.zero)
            
        case self.rulerScrollView:
            // рулер дней недели
            return self.info.date.startOfWeek.weeks(from: self.info.zero.startOfWeek)
            
        default:
            return 0
        }
    }
    
    func view(isv: InfiniteScrollView, index: Int) -> InfiniteScrollView.Info {
        switch isv {
        case self.daysScrollView:
            return .init(
                view: self.info.customization.dayView.init(
                    info:   self.info,
                    date:   self.info.zero.adding(.day, value: index) ?? Date(),
                    offset: self.offset,
                    input:  self.offsetSync.input
                ),
                length: .flexible(1)
            )
            
        case self.rulerScrollView:
            // рулер дней недели
            return .init(
                view: RulerView(
                    info: self.info,
                    date: self.info.zero.adding(.weekOfMonth, value: index) ?? Date()
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
            
            // обновим рулер
            self.updateRuler()
            
            // открутим рулер
            self.rulerScrollView.scroll(
                to: view.date.weeks(from: self.info.zero),
                animated: true
            )
            
        case self.rulerScrollView:
            // рулер дней недели
            let daysShift = self.info.date.days(from: self.info.date.startOfWeek)
            
            guard
                let view = view as? RulerView,
                let date = view.date.adding(.day, value: daysShift)
            else {
                return
            }
            
            // сообщим
            self.info.interaction.shown.input.send(value: (self, date))
            
            // обновим рулер
            self.updateRuler()
            
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
            guard let view = view as? DayViewProtocol else {
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
            
        case self.rulerScrollView:
            // рулер дней недели
            guard
                let view = view as? RulerView,
                let date = view.date(at: point)
            else {
                return
            }
            
            // сообщим
            self.info.interaction.shown.input.send(value: (self, date))
            
            // обновим рулер
            self.updateRuler()
            
            // открутим скроллер календаря
            self.daysScrollView.scroll(
                to: date.days(from: self.info.zero),
                animated: true
            )
            
        default:
            break
        }
    }
}
