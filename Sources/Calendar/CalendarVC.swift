//
//  CalendarVC.swift
//  Calendar
//
//  Created by Денис Либит on 14.04.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa
import InfiniteScrollView


open class CalendarVC: UIViewController {
    
    // MARK: - Инициализация
    
    public required init(
        title:         String,
        calendar:      Calendar = .autoupdatingCurrent,
        navigation:    Navigator.Kind,
        initial:       Section.Kind = .day,
        dataSource:    DataSourceProtocol,
        style:         Style = .default,
        selection:     Selection,
        customization: Customization = .none
    ) {
        // параметры
        Calendar.shared = calendar
        
        let info =
            Info(
                style: style,
                dataSource: dataSource,
                selection: selection,
                customization: customization
            )
        
        self.info = info
        self.navigation = navigation
        self.initial = initial
        
        // инициализируемся
        super.init(nibName: nil, bundle: nil)
        
        // навбар
        self.navigationItem.setup()
        
        // зацепим селекцию
        selection.controller = self
        
        // заголовок
        self.title = title
        
        // цепляем поток ошибок?
        if let errors = customization.errors {
            self.errors
                .observeValues(errors)
        }
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Свойства
    
    private let info:       Info
    private let navigation: Navigator.Kind
    private let initial:    Section.Kind
    
    public lazy var errors =
        self.info.dataSource.errors
    
    // MARK: - Вьюхи
    
    private var placeholder: UIViewController?
    
    private lazy var toolbar =
        ToolbarView(
            frame:     .zero,
            separator: .bottom,
            effect:    self.info.style.navbar.translucent ? .prominent : nil,
            color:     self.info.style.navbar.background
        )

    // MARK: - Навигатор
    
    fileprivate lazy var navigator: NavigatorProtocol = {
        switch self.navigation {
        case .regular: return Navigator.Regular(vc: self, info: self.info, initial: self.initial)
        case .compact: return Navigator.Compact(vc: self, info: self.info, initial: self.initial)
        }
    }()
    
    // MARK: - Жизненный цикл
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // свойства вьюхи
        self.view.backgroundColor = self.info.style.colors.background
        
        // поставим тулбар для компактного режима
        if self.navigation == .compact {
            self.view.addSubview(self.toolbar)
        }
        
        // подключим навигатор
        self.navigator.viewDidLoad()
        
        // состояние источника данных
        self.info.dataSource.state
            .producer
            .observe(on: QueueScheduler.main)
            .startWithValues { [weak self] state in
                guard let self = self else { return }
                
                // скроем прошлую заглушку, если была
                if let vc = self.placeholder {
                    self.placeholder = nil
                    
                    UIView.animate(
                        withDuration: 0.25,
                        animations: {
                            vc.view.alpha = 0
                        },
                        completion: { isFinished in
                            vc.willMove(toParent: nil)
                            vc.view.removeFromSuperview()
                            vc.removeFromParent()
                        }
                    )
                }
                
                // разберём состояние источника
                switch state {
                case .undetermined:
                    // скроем элементы календаря
                    self.navigator.set(hidden: true, animated: false)
                    
                case .ready:
                    // покажем элементы календаря
                    self.navigator.set(hidden: false, animated: true)
                    
                case .placeholder(let vc):
                    // скроем элементы календаря
                    self.navigator.set(hidden: true, animated: false)
                    
                    // ставим заглушку
                    self.addChild(vc)
                    vc.view.frame = self.view.bounds
                    vc.view.alpha = 0
                    self.view.addSubview(vc.view)
                    vc.didMove(toParent: self)
                    
                    UIView.animate(withDuration: 0.25) {
                        vc.view.alpha = 1
                    }
                    
                    // запомним
                    self.placeholder = vc
                }
            }
        
        // следим за изменениями в источнике данных
        self.info.dataSource.changes
            .observeValues { [weak self] changes in
                guard let self = self else { return }
                self.navigator.update()
            }
        
        // следим за календарными изменениями
        Signal
            .merge([
                NotificationCenter.default.reactive.notifications(forName: .NSCalendarDayChanged),
                NotificationCenter.default.reactive.notifications(forName: .NSSystemTimeZoneDidChange),
                NotificationCenter.default.reactive.notifications(forName: .NSSystemClockDidChange),
            ])
            .take(during: self.reactive.lifetime)
            .debounce(0, on: QueueScheduler.main)
            .observeValues { [weak self] notification in
                guard let self = self else { return }
                
                // сбросим календарные метрики
                self.info.update()
                
                // обновим или сбросим наполнение интерфейса
                switch notification.name {
                case .NSCalendarDayChanged: self.navigator.update()
                default:                    self.navigator.reload()
                }
            }
        
        // следим за изменениями локали
        NotificationCenter.default.reactive.notifications(forName: NSLocale.currentLocaleDidChangeNotification)
            .take(during: self.reactive.lifetime)
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] _ in
                guard let self = self else { return }
                
                // обновим календарные данные
                self.info.update()
                
                // обновим наполнение интерфейса
                self.navigator.update()
            }
    }
    
    // MARK: - Геометрия
    
    open override func viewWillLayoutSubviews() {
        let bounds:     CGRect  = self.view.bounds
        let insetted:   CGRect  = bounds.inset(by: self.view.safeAreaInsets)
        
        self.toolbar.frame =
            CGRect(
                x:      0,
                y:      0,
                width:  bounds.width,
                height: insetted.minY
            )
        
        // заглушка
        self.placeholder?.view.frame = bounds
        
        // основной интерфейс
        self.navigator.layoutSubviews()
    }
    
    // MARK: - Окружение
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.navigator.traitsChanged()
    }
}

// MARK: - Анимации перехода

extension CalendarVC {
    func layout(with monthVC: CalendarVC.Section.Compact.MonthVC) -> CalendarVC.Navigator.Compact.Animations.Layout {
        // дата
        let date = self.info.date
        
        // целевые вьюхи года и месяца
        guard
            let yearVC = self.children.first as? CalendarVC.Section.Shared.YearVC,
            let yearView = yearVC.view(for: date),
            let monthView = monthVC.view(for: date)

        else {
            return .empty
        }
        
        // геометрия
        var monthFrame:         CGRect  = .zero
        var diffRatio:          CGFloat = 0
        var monthViewCenter:    CGPoint = .zero
        var finalPosition:      CGPoint = .zero
        
        // получим блоки вёрстки контроллера года
        let yearLayout = yearVC.layout(with: monthVC)
        
        // вернём блоки вёрстки
        return .init(
            native: .init(
                prepare: {
                    // подготовим контроллер года
                    yearLayout.native.prepare()
                    
                    // сместим точку опоры на центр целевого месяца
                    self.view.layer.shiftAnchorPoint(
                        to: CGPoint(
                            x: monthFrame.midX / self.view.layer.bounds.width,
                            y: monthFrame.midY / self.view.layer.bounds.height
                        )
                    )
                },
                layout: {
                    // подвинем вьюху на место
                    self.view.layer.position = finalPosition
                    
                    // вернём нормальный масштаб вьюхе
                    self.view.transform = .identity
                    
                    // покажем
                    self.view.alpha = 1
                    
                    // сверстаем контроллер года
                    yearLayout.native.layout()
                },
                cleanup: { success in
                    // покажем тулбар
                    self.toolbar.alpha = 1
                    
                    // подчистим контроллер года
                    yearLayout.native.cleanup(success)
                    
                    // вернём нормальную точку опоры вьюхе контроллера года
                    self.view.layer.shiftAnchorPoint(to: CGPoint(x: 0.5, y: 0.5))
                }
            ),
            foreign: .init(
                prepare: {
                    // скроем тулбар
                    self.toolbar.alpha = 0
                    
                    // подготовим контроллер года
                    yearLayout.foreign.prepare()
                    
                    // координаты целевого года
                    guard
                        let monthData = yearView.coordinates.months.first(where: { $0.date.isEqual(to: date, precision: .month) })
                    else {
                        return
                    }
                    
                    // фрейм целевого месяца
                    monthFrame =
                        self.view.layer.convert(monthData.frame, from: yearView.layer)
                    
                    // конечная позиция для обратной анимации
                    finalPosition =
                        self.view.superview?.layer.convert(monthFrame.center, from: self.view.layer) ?? .zero
                    
                    // коэффициент различия размеров месяца года и целевого месяца
                    diffRatio =
                        max(
                            monthView.frame.width  / monthFrame.width,
                            monthView.frame.height / monthFrame.height
                        )
                    
                    // позиция целевой вьюхи месяца
                    monthViewCenter =
                        self.view.layer.convert(monthView.layer.bounds.center, from: monthView.layer)
                    
                    // сместим точку опоры на центр целевого месяца
                    self.view.layer.shiftAnchorPoint(
                        to: CGPoint(
                            x: monthFrame.midX / self.view.layer.frame.width,
                            y: monthFrame.midY / self.view.layer.frame.height
                        )
                    )
                },
                layout: {
                    // подвинем вьюху под центр месяца
                    self.view.layer.position = monthViewCenter
                    
                    // масштабируем под размер месяца
                    self.view.transform =
                        CGAffineTransform(scaleX: diffRatio, y: diffRatio)
                    
                    // прячем
                    self.view.alpha = 0
                    
                    // сверстаем контроллер года
                    yearLayout.foreign.layout()
                },
                cleanup: { success in
                    // покажем
                    self.view.alpha = 1
                    
                    // вернём нормальный масштаб вьюхе
                    self.view.transform = .identity
                    
                    // вернём нормальную точку опоры
                    self.view.layer.shiftAnchorPoint(to: CGPoint(x: 0.5, y: 0.5))
                    
                    // подчистим контроллер года
                    yearLayout.foreign.cleanup(success)
                }
            )
        )
    }
}
