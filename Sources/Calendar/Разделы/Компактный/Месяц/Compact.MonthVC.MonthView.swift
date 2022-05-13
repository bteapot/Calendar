//
//  Compact.MonthVC.MonthView.swift
//  Calendar
//
//  Created by Денис Либит on 28.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift


extension CalendarVC.Section.Compact.MonthVC {
    final class MonthView: UIView {
        
        // MARK: - Инициализация
        
        required init(
            info:  CalendarVC.Info,
            date:  Date
        ) {
            // параметры
            self.date  = date
            self.info  = info
            
            // свойства
            let weeksRange    = Calendar.shared.range(of: .weekOfMonth, in: .month, for: date) ?? 0..<6
            
            self.daysInMonth  = Calendar.shared.range(of: .day, in: .month, for: date)?.count ?? 0
            self.weeksInMonth = weeksRange.count
            self.firstWeek    = weeksRange.lowerBound
            
            // дни
            self.days =
                Array(0..<self.daysInMonth)
                    .compactMap { index in
                        if let date = date.adding(.day, value: index) {
                            return DayLayer(info: info, date: date)
                        } else {
                            return nil
                        }
                    }
            
            // линейки
            self.lines =
                Array(0..<self.weeksInMonth)
                    .map { _ in
                        return CALayer()
                    }
            
            // инициализация
            super.init(frame: .zero)
            
            // поставим данные
            self.update()
            
            // саблеера
            self.layer.addSublayer(self.title)
            self.days.forEach(self.layer.addSublayer)
            self.lines.forEach(self.layer.addSublayer)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Свойства
        
        let info:  CalendarVC.Info
        let date:  Date
        
        private let daysInMonth:  Int
        private let weeksInMonth: Int
        private let firstWeek:    Int
        
        // MARK: - Сабвьюхи
        
        private let title: CATextLayer = {
            let layer = CalendarVC.Section.Shared.CenteredTextLayer()
            layer.contentsScale = UIScreen.main.scale
            layer.contentsGravity = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
            layer.alignmentMode = .natural
            layer.truncationMode = .end
            return layer
        }()
        private let days:  [DayLayer]
        private let lines: [CALayer]
        
        // MARK: - Данные
        
        func date(at point: CGPoint) -> Date? {
            guard self.bounds.contains(point) else {
                return nil
            }
            
            return self.days
                .map { ($0, $0.position.squaredDistance(to: point)) }
                .min(by: { $0.1 < $1.1 })
                .map { $0.0.date }
        }
        
        func point(for date: Date) -> CGPoint? {
            return self.days
                .first(where: { $0.date.isEqual(to: date, precision: .day) })
                .map { $0.position - ($0.bounds.center - $0.textLayer.position) }
        }
        
        private var binding = Lifetime.make()
        
        func update() {
            // название месяца
            self.title.string = self.info.formatters.month.string(from: self.date).capitalized
            self.title.font = self.info.style.fonts.monthMonth
            self.title.fontSize = self.info.style.fonts.monthMonth.pointSize
            self.title.foregroundColor = self.date.isEqual(to: Date(), precision: .month) ? self.info.style.colors.tint.cgColor : self.info.style.colors.primary.cgColor
            
            // дни месяца
            self.days.forEach { $0.update() }
            
            // линейки недель
            self.lines.forEach { $0.backgroundColor = self.info.style.colors.separator.cgColor }
            
            // отключим прошлую процедуру получения событий
            self.binding = Lifetime.make()
            
            // запросим события
            self.info.dataSource.events(in: DateInterval(start: self.date, end: self.date.endOfMonth))
                .take(during: self.binding.lifetime)
                .startWithValues { [weak self] events in
                    guard let self = self else { return }
                    self.days.forEach { dayLayer in
                        let dayInterval = DateInterval(start: dayLayer.date, duration: 24 * 60 * 60)
                        dayLayer.events = events.filter { $0.interval.start < dayInterval.end && $0.interval.end >= dayInterval.start }
                    }
                }
        }
        
        // MARK: - Геометрия
        
        private var freezeLayout: Bool = false
        
        override func layoutSubviews() {
            guard self.freezeLayout == false else {
                return
            }
            
            self.layoutDayLayers()
            self.layoutTitleLayer()
            self.layoutLineLayers()
            
            // rtl
            self.layer.flipLayoutIfNeeded()
        }
        
        func layoutDayLayers() {
            let daysInWeek:     Int     = self.info.metrics.daysInWeek
            let firstWeek:      Int     = self.firstWeek
            let firstWeekday:   Int     = self.info.metrics.firstWeekday
            
            let titleHeight:    CGFloat = self.info.style.fonts.monthMonth.lineHeight.ceiled()
            let dayHeight:      CGFloat = DayLayer.height(with: self.info)
            
            let bounds:         CGRect  = self.bounds
            let inset:          CGFloat = self.info.style.geometry.inset
            let space:          CGFloat = bounds.width / CGFloat(daysInWeek)
            
            // даты
            self.days
                .enumerated()
                .forEach { index, layer in
                    guard
                        let startOfDay = self.date.adding(.day, value: index)
                    else {
                        return
                    }
                    
                    // день недели
                    let weekday: Int =
                        Calendar.shared.component(.weekday, from: startOfDay)
                    
                    // неделя
                    let week: Int =
                        Calendar.shared.component(.weekOfMonth, from: startOfDay)
                    
                    // позиция в сетке
                    let x: Int = (weekday - firstWeekday + daysInWeek) % daysInWeek
                    let y: Int = week - firstWeek
                    
                    // размер
                    layer.bounds.size =
                        CGSize(
                            width:  layer.width(),
                            height: dayHeight
                        )
                    
                    // позиция
                    layer.position =
                        CGPoint(
                            x: space * 0.5 + CGFloat(x) * space,
                            y: inset + titleHeight + dayHeight * 0.5 + CGFloat(y) * dayHeight
                        )
                }
        }
        
        func layoutTitleLayer() {
            let bounds:         CGRect  = self.bounds
            let inset:          CGFloat = self.info.style.geometry.inset
            
            // название месяца
            let dateFrame: CGRect =
                self.days.first?.frame ?? .zero
            
            let titleSize: CGSize =
                self.title.preferredFrameSize()
            
            self.title.frame =
                CGRect(
                    x:      min(dateFrame.minX, bounds.width - inset - titleSize.width),
                    y:      dateFrame.minY - titleSize.height,
                    width:  titleSize.width,
                    height: titleSize.height
                )
        }
        
        func layoutLineLayers() {
            let daysInWeek:     Int     = self.info.metrics.daysInWeek
            
            let lineHeight:     CGFloat = 1 / UIScreen.main.scale
            
            let bounds:         CGRect  = self.bounds
            let space:          CGFloat = bounds.width / CGFloat(daysInWeek)
            
            // линейки недель
            self.lines
                .enumerated()
                .forEach { weekIndex, lineLayer in
                    // фреймы лэеров дней этой недели
                    let frames: [CGRect] =
                        self.days
                            .filter { $0.date.weekOfMonth - self.firstWeek == weekIndex }
                            .map { $0.frame }
                    
                    // координаты
                    guard
                        let minY: CGFloat = frames.first?.minY,
                        let minX: CGFloat = weekIndex == 0 ? self.title.frame.minX : frames.map({ $0.minX }).min(),
                        let maxX: CGFloat = frames.map({ $0.maxX }).max()
                    else {
                        return
                    }
                    
                    let x:     CGFloat = minX < space ? 0 : minX
                    let width: CGFloat = (bounds.width - maxX < space ? bounds.width : maxX) - x
                    
                    // ставим фрейм
                    lineLayer.frame =
                        CGRect(
                            x:      x,
                            y:      minY,
                            width:  width,
                            height: lineHeight
                        )
                }
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let inset:          CGFloat = self.info.style.geometry.inset
            let titleHeight:    CGFloat = self.info.style.fonts.monthMonth.lineHeight.ceiled()
            let dayHeight:      CGFloat = DayLayer.height(with: self.info)
            
            return CGSize(
                width:  size.width,
                height: inset + titleHeight + CGFloat(self.weeksInMonth) * dayHeight
            ).ceiled()
        }
        
        // MARK: - Анимации перехода
        
        func dayLayer(for date: Date) -> DayLayer? {
            return self.days.first(where: { $0.date.isEqual(to: date, precision: .day) })
        }
        
        func maskShift() -> CGFloat {
            guard let dayLayer = self.days.first else {
                return 0
            }
            
            return DayLayer.height(with: self.info) / 2 + (dayLayer.bounds.center.y - dayLayer.textLayer.position.y)
        }
        
        func layout(with yearView: CalendarVC.Section.Shared.YearVC.YearView) -> CalendarVC.Navigator.Compact.Animations.Layout {
            // дата
            let date = self.info.date
            
            // параметры
            var monthLayout: () -> Void = {}
            var daysLayout: [() -> Void] = []
            
            // вернём блоки вёрстки
            return .init(
                native: .init(
                    prepare: {
                        
                    },
                    layout: {
                        // разрешим вёрстку
                        self.freezeLayout = false
                        
                        // вернём масштаб заголовку
                        self.title.fontSize =
                            self.info.style.fonts.monthMonth.pointSize
                        
                        // вернём изначальные параметры слоёв дней
                        self.days
                            .forEach { dayLayer in
                                dayLayer.freezeLayout = true
                                dayLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                                dayLayer.transform = CATransform3DIdentity
                                dayLayer.todayLayer.transform = CATransform3DIdentity
                                dayLayer.textLayer.fontSize = self.info.style.fonts.monthDay.pointSize
                                dayLayer.textLayer.transform = CATransform3DIdentity
                            }
                        
                        // включим линейки
                        self.lines.forEach {
                            $0.opacity = 1
                        }
                        
                        // расставим слои
                        self.setNeedsLayout()
                        self.layoutIfNeeded()
                    },
                    cleanup: { success in
                        // включим маркеры наличия событий
                        self.days
                            .forEach { dayLayer in
                                dayLayer.freezeLayout = false
                                dayLayer.eventsLayer.opacity = 1
                            }
                    }
                ),
                foreign: .init(
                    prepare: {
                        // отключим вёрстку
                        self.freezeLayout = true
                        
                        // коэффициент компрессии шрифтов во вьюхе года
                        let fontsRatio: CGFloat =
                            yearView.geometry.fontsRatio
                        
                        // радиус маркера текущего дня
                        let markerRatio: CGFloat =
                            (yearView.geometry.markerRadius * 2) /
                            CalendarVC.Section.Compact.MonthVC.MonthView.DayLayer.todayDiameter(with: self.info)
                        
                        // вёрстка дней
                        daysLayout =
                            self.days
                                .map { dayLayer in
                                    // найдём координаты дня во вьюхе года, соответствующие слою дня во вьюхе месяца
                                    guard
                                        let yearDayData =
                                            yearView.coordinates.days
                                                .first(where: { $0.date.isEqual(to: dayLayer.date, precision: .day) })
                                    else {
                                        return {}
                                    }
                                    
                                    // запретим вёрстку
                                    dayLayer.freezeLayout = true
                                    
                                    // скроем метку наличия событий
                                    dayLayer.eventsLayer.opacity = 0
                                    
                                    // опорная точка слоя под центр метки дня
                                    let anchorPoint: CGPoint =
                                        CGPoint(
                                            x: dayLayer.textLayer.position.x / dayLayer.bounds.width,
                                            y: dayLayer.textLayer.position.y / dayLayer.bounds.height
                                        )
                                    
                                    // центр метки дня вьюхи года
                                    let position: CGPoint =
                                        self.layer.convert(yearDayData.position, from: yearView.layer)
                                    
                                    // вернём блок анимации
                                    return {
                                        // сдвинем опорную точку слоя под центр метки дня
                                        dayLayer.anchorPoint =
                                            anchorPoint
                                        
                                        // отцентруем по метке дня вьюхи года
                                        dayLayer.position =
                                            position
                                        
                                        // сожмём
                                        dayLayer.transform =
                                            CATransform3DMakeScale(fontsRatio, fontsRatio, 1)
                                        
                                        // приведём размер маркера текущего дня к размеру маркера во вьюхе года
                                        dayLayer.todayLayer.transform =
                                            CATransform3DMakeScale(markerRatio / fontsRatio, markerRatio / fontsRatio, 1)
                                        
                                        // поставим шрифт метки дня
                                        dayLayer.textLayer.fontSize =
                                            self.info.style.fonts.monthDay.pointSize * fontsRatio
                                        
                                        // скомпенсируем изменение размера шрифта
                                        dayLayer.textLayer.transform =
                                            CATransform3DMakeScale(1 / fontsRatio, 1 / fontsRatio, 1)
                                    }
                                }
                        
                        // фрейм заголовка месяца
                        let yearViewTitleFrame: CGRect =
                            self.layer.convert(
                                yearView.coordinates.titles
                                    .first(where: { $0.date.isEqual(to: date, precision: .month) })
                                    .map({ $0.frame })
                                ?? .zero,
                                from: yearView.layer
                            )
                        
                        // вёрстка месяца
                        monthLayout = {
                            // поставим метку названия месяца
                            self.title.frame =
                                yearViewTitleFrame.expanded(by: .init(vertical: yearViewTitleFrame.height * fontsRatio))
                            
                            self.title.fontSize =
                                self.info.style.fonts.monthMonth.pointSize * fontsRatio
                            
                            // расставим слои линеек целевого месяца
                            self.layoutLineLayers()
                            
                            // заглушим линейки во вьюхе целевого месяца
                            self.lines.forEach {
                                $0.opacity = 0
                            }
                        }
                    },
                    layout: {
                        // расставим метки дней по меткам дней вьюхи года
                        daysLayout.forEach { $0() }
                        
                        // сверстаем всё остальное
                        monthLayout()
                    },
                    cleanup: { success in
                        // разрешим вёрстку
                        self.freezeLayout = false
                        
                        // неудачно?
                        if success == false {
                            // включим линейки
                            self.lines.forEach {
                                $0.opacity = 1
                            }
                            
                            // включим маркеры наличия событий
                            self.days
                                .forEach {
                                    $0.freezeLayout = false
                                    $0.eventsLayer.opacity = 1
                                }
                            
                            // расставим слои
                            self.setNeedsLayout()
                            self.layoutIfNeeded()
                        }
                    }
                )
            )
        }
        
        func layout(
            dayVC:     CalendarVC.Section.Compact.DayVC,
            targetY:   CGFloat,
            deltaUp:   CGFloat,
            deltaDown: CGFloat
        ) -> CalendarVC.Navigator.Compact.Animations.Layout {
            // вьюха рулера контроллера дня
            guard
                let rulerView = dayVC.rulerView()
            else {
                return .empty
            }
            
            // координаты дней недели рулера контроллера дня
            let targetDates: [Date] =
                rulerView.elements
                    .map {weekdayLayer in
                        return weekdayLayer.date
                    }
            
            // вернём блоки вёрстки
            return .init(
                native: .init(
                    prepare: {
                        
                    },
                    layout: {
                        // разрешим вёрстку
                        self.freezeLayout = false
                        
                        // включим линейки
                        self.lines.forEach {
                            $0.opacity = 1
                        }
                        
                        // расставим слои
                        self.setNeedsLayout()
                        self.layoutIfNeeded()
                    },
                    cleanup: { success in
                        // покажем слои дней целевой недели
                        self.days
                            .forEach {
                                $0.isHidden = false
                            }
                    }
                ),
                foreign: .init(
                    prepare: {
                        // спрячем дни целевой недели
                        self.days
                            .filter { dayLayer in
                                return targetDates.contains(where: { $0.isEqual(to: dayLayer.date, precision: .day) })
                            }
                            .forEach {
                                $0.isHidden = true
                            }
                    },
                    layout: {
                        // выключим вёрстку
                        self.freezeLayout = true
                        
                        // блок сдвига слоя
                        let move = { (layer: CALayer) in
                            if layer.position.y <= targetY {
                                // двигаем вверх
                                layer.position.y -= deltaUp
                            } else {
                                // двигаем вниз
                                layer.position.y += deltaDown
                            }
                        }
                        
                        // подвинем дни
                        self.days.forEach(move)
                        
                        // подвинем линейки
                        self.lines.forEach { layer in
                            move(layer)
                            layer.opacity = 0
                        }
                        
                        // подвинем метку месяца
                        move(self.title)
                    },
                    cleanup: { success in
                        // разрешим вёрстку
                        self.freezeLayout = false
                        
                        // включим линейки
                        self.lines.forEach {
                            $0.opacity = 1
                        }
                        
                        // покажем слои дней
                        self.days
                            .forEach {
                                $0.isHidden = false
                            }
                        
                        // расставим слои
                        self.setNeedsLayout()
                        self.layoutIfNeeded()
                    }
                )
            )
        }
    }
}
