//
//  DayVC.DayView.swift
//  Calendar
//
//  Created by Денис Либит on 03.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift


extension CalendarVC.Section.Shared {
    public final class DayView: UIView, DayViewProtocol {
        
        // MARK: - Инициализация
        
        public required init(
            info:   CalendarVC.Info,
            date:   Date,
            offset: CGFloat,
            input:  Signal<(DayViewProtocol, CGFloat), Never>.Observer
        ) {
            // стиль
            self.info = info
            self.date = date
            self.initialOffset = offset
            self.offsetInput = input
            
            // инициализируемся
            super.init(frame: .zero)
            
            // свойства
            self.isOpaque = true
            self.backgroundColor = info.style.colors.background
            
            // поставим данные
            self.update()
            
            // выбранное событие
            info.selection.producer
                .startWithValues { [weak self] event in
                    guard let self = self else { return }
                    self.select(event: event)
                }
            
            // сабвьюхи
            self.addSubview(self.dayScrollView)
            self.addSubview(self.alldayScrollView)
            self.addSubview(self.alldayLabel)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Свойства
        
        public static var standardSelection: Bool = true
        
        public let info: CalendarVC.Info
        public let date: Date
        
        // MARK: - Весь день
        
        private lazy var alldayScrollView: UIScrollView = {
            let scrollView = UIScrollView(frame: .zero)
            scrollView.scrollsToTop = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.backgroundColor = self.info.style.colors.separator
            return scrollView
        }()
        
        private lazy var alldayLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.text = NSLocalizedString("весь день", comment: "Метка раздела событий на весь день в секции дня.")
            label.font = self.info.style.fonts.dayAllday
            label.textColor = self.info.style.colors.primary
            return label
        }()
        
        private var alldayEventViews: [CalendarVC.EventView] = []
        
        private func update(allday events: [CalendarEventProtocol]) {
            // вьюхи исчезнувших событий
            let delete: [CalendarVC.EventView] =
                self.alldayEventViews
                    .filter { view in events.contains(where: { $0.isEqual(to: view.event) }) == false }
            
            // вьюхи сохранившихся событий
            let update: [CalendarVC.EventView] =
                self.alldayEventViews
                    .filter { view in
                        if let event = events.first(where: { $0.isEqual(to: view.event) }) {
                            // обновим данные вьюхи
                            view.event = event
                            return true
                        } else {
                            return false
                        }
                    }
            
            // вьюхи появившихся событий
            let insert: [CalendarVC.EventView] =
                events
                    .filter { event in self.alldayEventViews.contains(where: { $0.event.isEqual(to: event) }) == false }
                    .map {
                        CalendarVC.EventView(
                            info: self.info,
                            mode: .normal(handle: false),
                            event: $0
                        )
                    }
            
            // соберём новый список
            self.alldayEventViews =
                (update + insert).sorted(by: { $0.event.title < $1.event.title })
            
            // уберём исчезнувшие
            delete.forEach { $0.removeFromSuperview() }
            
            // добавим появившиеся
            insert.forEach { self.alldayScrollView.addSubview($0) }
        }
        
        // MARK: - День
        
        private lazy var dayScrollView: UIScrollView = {
            let scrollView = UIScrollView(frame: .zero)
            scrollView.scrollsToTop = false
            scrollView.showsHorizontalScrollIndicator = false
            
            self.ticks.forEach {
                scrollView.layer.addSublayer($0.time)
                scrollView.layer.addSublayer($0.line)
            }
            
            scrollView.layer.addSublayer(self.notchTime)
            scrollView.layer.addSublayer(self.notchLine)
            scrollView.layer.addSublayer(self.notchKnob)
            
            return scrollView
        }()
        
        private var dayEventViews: [CalendarVC.EventView] = []
        
        private func update(day events: [CalendarEventProtocol]) {
            // вьюхи исчезнувших событий
            let delete: [CalendarVC.EventView] =
                self.dayEventViews
                    .filter { view in events.contains(where: { $0.isEqual(to: view.event) }) == false }
            
            // вьюхи сохранившихся событий
            let update: [CalendarVC.EventView] =
                self.dayEventViews
                    .filter { view in
                        if let event = events.first(where: { $0.isEqual(to: view.event) }) {
                            // обновим данные вьюхи
                            view.event = event
                            return true
                        } else {
                            return false
                        }
                    }
            
            // вьюхи появившихся событий
            let insert: [CalendarVC.EventView] =
                events
                    .filter { event in self.dayEventViews.contains(where: { $0.event.isEqual(to: event) }) == false }
                    .map {
                        CalendarVC.EventView(
                            info: self.info,
                            mode: .normal(handle: true),
                            event: $0
                        )
                    }
            
            // соберём новый список
            self.dayEventViews =
                (update + insert).sorted(by: { $0.event.interval.start < $1.event.interval.start })
            
            // уберём исчезнувшие
            delete.forEach { $0.removeFromSuperview() }
            
            // добавим появившиеся
            insert.forEach { self.dayScrollView.addSubview($0) }
        }
        
        // MARK: - Часовая разметка
        
        private struct Tick {
            let hour: Int
            let time: CATextLayer
            let line: CALayer
            
            init(with hour: Int) {
                // параметры
                self.hour = hour
                
                // время
                self.time = CATextLayer()
                self.time.anchorPoint = CGPoint(x: 1, y: 0.5)
                self.time.alignmentMode = .right
                self.time.contentsScale = UIScreen.main.scale
                
                // линейка
                self.line = CALayer()
            }
            
            func update(
                info: CalendarVC.Info,
                date: Date
            ) {
                // время
                self.time.string = info.formatters.hour.string(from: date.adding(.hour, value: self.hour) ?? date)
                self.time.font = info.style.fonts.dayTime
                self.time.fontSize = info.style.fonts.dayTime.pointSize
                self.time.foregroundColor = info.style.colors.secondary.cgColor
                
                // линейка
                self.line.backgroundColor = info.style.colors.separator.cgColor
            }
        }
        
        private let ticks: [Tick] =
            Array(0...24).map(Tick.init)
        
        // MARK: - Метка текущего времени
        
        private lazy var notchTime: CATextLayer = {
            let layer = CATextLayer()
            layer.zPosition = 1
            layer.anchorPoint = CGPoint(x: 1, y: 0.5)
            layer.alignmentMode = .right
            layer.contentsScale = UIScreen.main.scale
            return layer
        }()
        
        private lazy var notchLine: CALayer = {
            let layer = CALayer()
            layer.zPosition = 1
            return layer
        }()
        
        private lazy var notchKnob: CALayer = {
            let layer = CALayer()
            layer.zPosition = 1
            layer.masksToBounds = true
            return layer
        }()
        
        // MARK: - Сдвиг
        
        private let initialOffset: CGFloat
        private let offsetInput: Signal<(DayViewProtocol, CGFloat), Never>.Observer
        
        public func set(offset: CGFloat) {
            let delegate = self.dayScrollView.delegate
            self.dayScrollView.delegate = nil
            self.dayScrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            self.dayScrollView.delegate = delegate
        }
        
        // MARK: - Данные
        
        private var binding = Lifetime.make()
        
        public func update() {
            // часовые отметки
            self.ticks.forEach {
                $0.update(info: self.info, date: self.date)
            }
            
            // текущее время
            self.notchTime.font = self.info.style.fonts.dayTime
            self.notchTime.fontSize = self.info.style.fonts.dayTime.pointSize
            self.notchTime.foregroundColor = self.info.style.colors.tint.cgColor
            
            self.notchLine.backgroundColor = self.info.style.colors.tint.cgColor
            self.notchKnob.backgroundColor = self.info.style.colors.tint.cgColor
            
            // отключим прошлую процедуру получения событий
            self.binding = Lifetime.make()
            
            // запросим события
            self.info.dataSource.events(in: DateInterval(start: self.date, end: self.date.endOfDay))
                .take(during: self.binding.lifetime)
                .startWithValues { [weak self] events in
                    guard let self = self else { return }
                    
                    // разберём события на "весь день" и обычные
                    self.update(allday: events.filter({ $0.isAllDay == true  }))
                    self.update(day:    events.filter({ $0.isAllDay == false }))
                }
            
            // обозначим необходимость перевёрстки
            self.setNeedsLayout()
        }
        
        // MARK: - Геометрия
        
        public override func layoutSubviews() {
            let rtl:                Bool    = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            
            let bounds:             CGRect  = self.bounds
            let insetted:           CGRect  = bounds.inset(by: self.safeAreaInsets)
            let inset:              CGFloat = self.info.style.geometry.inset
            
            let hourHeight:         CGFloat = (self.info.style.fonts.eventNormal.lineHeight * 4).ceiled()
            let tickTimeSize:       CGSize  = self.ticks.first?.time.preferredFrameSize() ?? .zero
            
            let alldayLabelSize:    CGSize  = self.alldayLabel.sizeThatFits(bounds.size).ceiled()
            let alldayInset:        CGFloat = inset / 4
            let alldayEventHeight:  CGFloat = (self.info.style.fonts.eventNormal.lineHeight + inset / 2).ceiled()
            let spine:              CGFloat = insetted.minX + inset + max(alldayLabelSize.width, tickTimeSize.width) + inset
            
            let alldayFullWidth:    CGFloat = bounds.width - spine - alldayInset
            let alldayHalfWidth:    CGFloat = (alldayFullWidth - alldayInset) / 2
            
            // события на весь день
            var alldayMaxY: CGFloat = 0
            
            self.alldayEventViews
                .enumerated()
                .forEach { index, view in
                    let row = CGFloat(index / 2)
                    let col = CGFloat(index % 2)
                    
                    view.frame =
                        CGRect(
                            x:      col * (alldayHalfWidth + alldayInset),
                            y:      alldayInset + row * (alldayEventHeight + alldayInset),
                            width:  index + 1 == self.alldayEventViews.count && col == 0 ? alldayFullWidth : alldayHalfWidth,
                            height: alldayEventHeight
                        )
                        .ceiled()
                    
                    alldayMaxY = view.frame.maxY
                }
            
            self.alldayScrollView.frame =
                CGRect(
                    x:      0,
                    y:      insetted.minY,
                    width:  bounds.width,
                    height: self.alldayEventViews.isEmpty ? 0 : min(alldayMaxY + alldayInset, (alldayEventHeight + alldayInset) * 2.5)
                )
                .ceiled()
            
            self.alldayScrollView.contentInset =
                rtl ? UIEdgeInsets(right: spine) : UIEdgeInsets(left: spine)
            
            self.alldayScrollView.contentSize =
                CGSize(
                    width:  insetted.width - spine,
                    height: alldayMaxY + alldayInset
                )
            
            // метка "весь день"
            self.alldayLabel.frame =
                CGRect(
                    x:      spine - alldayLabelSize.width - inset,
                    y:      inset - (self.info.style.fonts.dayAllday.ascender - self.info.style.fonts.dayAllday.xHeight),
                    width:  alldayLabelSize.width,
                    height: alldayLabelSize.height
                )
                .ceiled()
            
            self.alldayLabel.isHidden =
                self.alldayEventViews.isEmpty
            
            // обычные события
            let fullWidth:              CGFloat = insetted.width - spine - alldayInset
            let overlapHeightInMinutes: Int     = Int(ceil(60 * (tickTimeSize.height * 2) / hourHeight))
            
            let startDate: Date = self.date
            let endDate:   Date = startDate.endOfDay
            
            var dayEventViews: [CalendarVC.EventView] =
                self.dayEventViews
                    .sorted(by: { $0.event.interval.start < $1.event.interval.start })
            
            var firstEventViews: [CalendarVC.EventView] = []
            
            while dayEventViews.isEmpty == false {
                guard let firstEventView = dayEventViews.first else {
                    continue
                }
                
                firstEventViews.append(firstEventView)
                
                let precedingFirstEventViews: [CalendarVC.EventView] =
                    firstEventViews
                        .filter { view in
                            view.event.interval.start <= firstEventView.event.interval.end &&
                            view.event.interval.end   >  firstEventView.event.interval.start
                        }
                
                let leveledStartPosition: CGFloat =
                    precedingFirstEventViews.isEmpty ? 0 : 4 * CGFloat(precedingFirstEventViews.count - 1)
                
                let leveledEventViews: [CalendarVC.EventView] =
                    self.levelled(for: firstEventView, overlap: overlapHeightInMinutes)
                        .sorted(by: { lhs, rhs in
                            if lhs.event.interval.start == rhs.event.interval.start {
                                return lhs.event.title < rhs.event.title
                            } else {
                                return lhs.event.interval.start < rhs.event.interval.start
                            }
                        })
                
                let w: CGFloat = (fullWidth - leveledStartPosition) / CGFloat(leveledEventViews.count)
                
                leveledEventViews
                    .enumerated()
                    .forEach { index, view in
                        let sd: Date = view.event.interval.start >= startDate ? view.event.interval.start : startDate
                        let ed: Date = view.event.interval.end   <= endDate   ? view.event.interval.end   : endDate
                        
                        let sm: CGFloat = CGFloat(startDate.minutes(to: sd))
                        let em: CGFloat = CGFloat(startDate.minutes(to: ed))
                        
                        let sy: CGFloat = tickTimeSize.height + hourHeight * (sm / 60)
                        let ey: CGFloat = tickTimeSize.height + hourHeight * (em / 60)
                        
                        view.frame =
                            CGRect(
                                x:      spine + leveledStartPosition + w * CGFloat(index) + 1,
                                y:      sy + 1,
                                width:  w - alldayInset,
                                height: max(24, ey - sy - 2)
                            )
                            .ceiled()
                    }
                
                dayEventViews.removeAll(where: { leveledEventViews.contains($0) })
            }
            
            // вертикальные отступы родительской скроллвьюхи
            let parentInsets: UIEdgeInsets = {
                if let sv = self.superview as? UIScrollView {
                    return sv.adjustedContentInset
                } else {
                    return .zero
                }
            }()
            
            // ставим скроллвьюху обычных событий
            self.dayScrollView.frame =
                CGRect(
                    x:      0,
                    y:      -parentInsets.top,
                    width:  bounds.width,
                    height: bounds.height + parentInsets.top
                )
                .ceiled()
            
            self.dayScrollView.contentInset =
                UIEdgeInsets(top: parentInsets.top + self.alldayScrollView.frame.height)
            
            self.dayScrollView.scrollIndicatorInsets =
                self.dayScrollView.contentInset
            
            self.dayScrollView.contentSize =
                CGSize(
                    width:  insetted.width,
                    height: tickTimeSize.height + hourHeight * 24 + tickTimeSize.height
                )
            
            // часовые риски
            self.ticks.forEach { tick in
                // время
                tick.time.bounds.size =
                    tick.time.preferredFrameSize()
                
                tick.time.position =
                    CGPoint(
                        x: spine - inset,
                        y: tickTimeSize.height + CGFloat(tick.hour) * hourHeight
                    )
                
                // линейка
                tick.line.frame =
                    CGRect(
                        x:      spine - inset / 4,
                        y:      tick.time.position.y,
                        width:  bounds.width - (spine - inset / 4),
                        height: 1 / UIScreen.main.scale
                    )
            }
            
            // текущее время
            let now:        Date            = Date()
            let components: DateComponents  = Calendar.shared.dateComponents([.hour, .minute], from: now)
            let isNotToday: Bool            = self.date.isToday == false
            let notchY:     CGFloat         = tickTimeSize.height + CGFloat(components.hour ?? 0) * hourHeight + CGFloat(components.minute ?? 0) * (hourHeight / 60)
            let knobRadius: CGFloat         = 4
            
            self.notchTime.isHidden = isNotToday
            self.notchLine.isHidden = isNotToday
            self.notchKnob.isHidden = isNotToday
            
            self.notchTime.string =
                self.info.formatters.hour.string(from: now)
            
            self.notchTime.bounds.size =
                self.notchTime.preferredFrameSize()
            
            self.notchTime.position =
                CGPoint(
                    x: spine - inset,
                    y: notchY
                )
            
            self.notchLine.frame =
                CGRect(
                    x:      spine - inset / 2,
                    y:      notchY,
                    width:  bounds.width - (spine - inset / 2),
                    height: 1 / UIScreen.main.scale
                )
            
            self.notchKnob.bounds.size =
                CGSize.square(knobRadius * 2)
            
            self.notchKnob.cornerRadius =
                knobRadius
            
            self.notchKnob.position =
                CGPoint(
                    x: spine + 1,
                    y: notchY
                )
            
            if self.date.isToday {
                self.ticks.forEach { tick in
                    tick.time.isHidden = tick.time.frame.intersects(self.notchTime.frame)
                }
            }
            
            // первый раз?
            if self.dayScrollView.delegate == nil {
                // поставим текущий сдвиг раздела "день"
                self.set(offset: self.initialOffset)
                
                // начинаем следить за сдвигом
                self.dayScrollView.delegate = self
                
                // подкрутим к текущему времени, если это сейчас
                self.scrollToNowIfToday(animated: false)
            }
            
            // rtl
            self.flipLayoutIfNeeded()
            self.dayScrollView.layer.flipLayoutIfNeeded()
        }
        
        private func levelled(
            for view:        CalendarVC.EventView,
            known:           Set<CalendarVC.EventView> = [],
            overlap minutes: Int
        ) -> Set<CalendarVC.EventView> {
            var result = Set<CalendarVC.EventView>(known)
            result.insert(view)
            
            let start:   Date = view.event.interval.start
            let overlap: Date = start.adding(.minute, value: minutes) ?? start
            
            var levelled =
                Set<CalendarVC.EventView>(
                    self.dayEventViews
                        .filter { view in
                            view.event.interval.start >= start &&
                            view.event.interval.start <  overlap
                        }
                )
            
            levelled.subtract(known)
            
            levelled.forEach { view in
                result.formUnion(
                    self.levelled(for: view, known: result, overlap: minutes)
                )
            }
            
            return result
        }
        
        // MARK: - Окружение
        
        public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.update()
        }
        
        // MARK: - Прокрутка
        
        public func scrollToNowIfToday(animated: Bool) {
            if self.date.isToday {
                // прокрутим к текущему времени
                let bounds:     CGRect  = self.bounds
                let insetted:   CGRect  = bounds.inset(by: self.safeAreaInsets)
                
                let rect: CGRect =
                    self.notchTime.frame
                        .expanded(by: .init(vertical: insetted.height / 2))
                
                self.dayScrollView.scrollRectToVisible(rect, animated: animated)
            }
        }
        
        // MARK: - Выбор события
        
        public func eventInfos(at point: CGPoint) -> [DayViewProtocol.EventInfo] {
            // тап в событиях всего дня?
            if self.alldayScrollView.frame.contains(point) {
                let alldayPoint = self.alldayScrollView.convert(point, from: self)
            
                if let view = self.alldayEventViews.first(where: { $0.frame.contains(alldayPoint) }) {
                    return [(event: view.event, view: view)]
                }
            }
            
            // в обычных событиях?
            if self.dayScrollView.frame.contains(point) {
                let dayPoint = self.dayScrollView.convert(point, from: self)
                return self.dayEventViews
                    .filter { $0.frame.contains(dayPoint) }
                    .map { ($0.event, $0) }
                    .reversed()
            }
            
            // в молоко
            return []
        }
        
        private func select(event: CalendarEventProtocol?) {
            if let event = event {
                self.alldayEventViews.forEach { view in
                    if view.event.isEqual(to: event) {
                        view.isSelected = true
                        self.alldayScrollView.scrollRectToVisible(view.frame.expanded(by: .init(vertical: self.info.style.geometry.inset)), animated: true)
                    } else {
                        view.isSelected = false
                    }
                }
                self.dayEventViews.forEach { view in
                    if view.event.isEqual(to: event) {
                        view.isSelected = true
                        self.dayScrollView.scrollRectToVisible(view.frame.expanded(by: .init(vertical: self.info.style.geometry.inset)), animated: true)
                    } else {
                        view.isSelected = false
                    }
                }
            } else {
                self.alldayEventViews.forEach { $0.isSelected = false }
                self.dayEventViews.forEach    { $0.isSelected = false }
            }
        }
    }
}

extension CalendarVC.Section.Shared.DayView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.dayScrollView {
            self.offsetInput.send(value: (self, self.dayScrollView.contentOffset.y))
        }
    }
}
