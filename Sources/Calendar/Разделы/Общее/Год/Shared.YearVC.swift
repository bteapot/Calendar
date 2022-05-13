//
//  YearVC.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


extension CalendarVC.Section.Shared {
    final class YearVC: UIViewController, RegularSectionProtocol {
        
        // MARK: - Инициализация
        
        required init(_ info: CalendarVC.Info) {
            // параметры
            self.info = info
            
            // инициализируемся
            super.init(nibName: nil, bundle: nil)
            
            // поставим заголовок
            self.updateTitle(with: info.date)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Очередь рендера
        
        private lazy var queue =
            DispatchQueue(
                label: "calendar.year-view.drawing",
                qos: .userInteractive,
                attributes: [.concurrent],
                autoreleaseFrequency: .workItem
            )
        
        // MARK: - Протокол Section
        
        var kind: CalendarVC.Section.Kind = .year
        let info: CalendarVC.Info
        
        func reload() {
            self.scrollView.reset()
            self.updateTitle(with: self.info.date)
        }
        
        func update() {
            self.scrollView.items
                .compactMap { $0.view as? YearView }
                .forEach {
                    $0.update()
                }
            
            self.updateTitle(with: self.info.date)
        }
        
        func scroll(to date: Date, animated: Bool) {
            self.scrollView.scroll(
                to: date.startOfYear.years(from: self.info.zero),
                animated: animated
            )
            
            self.updateTitle(with: date)
        }
        
        lazy var display: Property<(Date?, Bool)> =
            Property<Date?>(
                initial: nil,
                then: self.displayPipe.output
            )
            .map { ($0, false) }
        
        private let displayPipe =
            Signal<Date?, Never>.pipe()
        
        lazy var ruler: CalendarVC.Navigator.Ruler? = nil
        
        // MARK: - Вьюха
        
        private lazy var scrollView =
            InfiniteScrollView(
                frame: UIScreen.main.bounds,
                direction: .vertical,
                dataSource: self,
                reserve: UIScreen.main.bounds.height / 2
            )
        
        // MARK: - Жизненный цикл
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // фон
            self.view.backgroundColor = self.info.style.colors.background
            
            // зацепим скроллвьюху
            self.scrollView.delegate = self
            
            // сабвьюхи
            self.view.addSubview(self.scrollView)
        }
        
        // MARK: - Геометрия
        
        override func viewWillLayoutSubviews() {
            self.scrollView.frame = self.view.bounds
        }
        
        // MARK: - Инструменты
        
        private func updateTitle(with date: Date) {
            self.title = self.info.formatters.year.string(from: date)
        }
    }
}

// MARK: - Источник данных InfiniteScrollView

extension CalendarVC.Section.Shared.YearVC: InfiniteScrollViewDataSource {
    func initialIndex(isv: InfiniteScrollView) -> Int {
        self.info.date.startOfYear.years(from: self.info.zero)
    }
    
    func view(isv: InfiniteScrollView, index: Int) -> InfiniteScrollView.Info {
        return .init(
            view: YearView(
                info:  self.info,
                date:  self.info.zero.adding(.year, value: index) ?? Date(),
                queue: self.queue
            ),
            length: .auto
        )
    }
    
    func shown(isv: InfiniteScrollView, view: UIView, index: Int) {
        let daysShift = self.info.date.days(from: self.info.date.startOfYear)
        
        guard
            let view = view as? YearView,
            let date = view.date.adding(.day, value: daysShift)
        else {
            return
        }
        
        // сообщим
        self.info.interaction.shown.input.send(value: (self, date))
        
        // обновим заголовок
        self.updateTitle(with: date)
    }
    
    func tap(isv: InfiniteScrollView, view: UIView, index: Int, point: CGPoint) {
        guard
            let view = view as? YearView,
            let date = view.date(at: point)
        else {
            return
        }
        
        // сообщим
        self.info.interaction.tapped.input.send(value: (self, date))
        
        // обновим заголовок
        self.updateTitle(with: date)
    }
}

// MARK: - Делегат UIScrollView

extension CalendarVC.Section.Shared.YearVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // обновим метку периода
        
        // точка прямо под тулбаром
        let point: CGPoint =
            scrollView.convert(CGPoint(x: 0, y: self.view.safeAreaInsets.top), from: self.view)
        
        // вьюха года в точке
        guard let view = scrollView.subviews.first(where: { $0.frame.contains(point) }) as? YearView else {
            return
        }
        
        // где-то поблизости от края?
        if view.frame.inset(by: UIEdgeInsets(vertical: 32)).contains(point) {
            // далеко от края, показываем год
            self.displayPipe.input.send(value: view.date)
        } else {
            // близко от края, прячем метку года
            self.displayPipe.input.send(value: nil)
        }
    }
}

// MARK: - Анимации перехода

extension CalendarVC.Section.Shared.YearVC {
    func view(for date: Date) -> YearView? {
        return self.scrollView.items
            .compactMap({ $0.view as? YearView })
            .first(where: { $0.date.isEqual(to: date, precision: .year) })
    }
    
    func layout(with monthVC: CalendarVC.Section.Compact.MonthVC) -> CalendarVC.Navigator.Compact.Animations.Layout {
        // дата
        let date = self.info.date
        
        // целевые вьюхи года и месяца
        guard
            let yearView = self.view(for: date),
            let monthView = monthVC.view(for: date)
        else {
            return .empty
        }
        
        // остановим прокрутку
        self.scrollView.setContentOffset(self.scrollView.contentOffset, animated: false)
        
        // отрисуем вьюхи лет
        self.scrollView.items
            .compactMap({ $0.view as? CalendarVC.Section.Shared.YearVC.YearView })
            .forEach { view in
                if view.layer.contents == nil {
                    view.draw(now: true)
                }
            }
        
        // получим блоки вёрстки вьюхи целевого года
        let viewLayout = yearView.layout(with: monthView)
        
        // вернём блоки вёрстки
        return .init(
            native: .init(
                prepare: {
                    viewLayout.native.prepare()
                },
                layout: {
                    viewLayout.native.layout()
                },
                cleanup: { success in
                    viewLayout.native.cleanup(success)
                }
            ),
            foreign: .init(
                prepare: {
                    viewLayout.foreign.prepare()
                },
                layout: {
                    viewLayout.foreign.layout()
                },
                cleanup: { success in
                    if success {
                        // юзер мог тапнуть не по отцентрованному году
                        self.reload()
                    } else {
                        // подчистка вьюхи
                        viewLayout.foreign.cleanup(success)
                    }
                }
            )
        )
    }
}
