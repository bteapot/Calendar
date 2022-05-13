//
//  YearVC.YearView.swift
//  Calendar
//
//  Created by Денис Либит on 29.04.2021.
//

import Foundation
import UIKit


extension CalendarVC.Section.Shared.YearVC {
    final class YearView: UIView {
        
        // MARK: - Инициализация
        
        required init(
            info:  CalendarVC.Info,
            date:  Date,
            queue: DispatchQueue
        ) {
            // параметры
            self.info  = info
            self.date  = date
            self.queue = queue
            
            // инициализация
            super.init(frame: .zero)
            
            // свойства
            self.isOpaque = true
            self.backgroundColor = info.style.colors.background
            
            self.layer.contentsGravity = .topLeft
            self.layer.contentsScale = UIScreen.main.scale
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Свойства
        
        let info:  CalendarVC.Info
        let date:  Date
        
        private let queue: DispatchQueue
        
        var coordinates: Geometry.Coordinates = .empty
        
        // MARK: - Данные
        
        func date(at point: CGPoint) -> Date? {
            guard self.bounds.contains(point) else {
                return nil
            }
            
            return self.coordinates.days
                .map { ($0.date, $0.position.squaredDistance(to: point)) }
                .min(by: { $0.1 < $1.1 })
                .map { $0.0 }
        }
        
        // MARK: - Рисование
        
        func update() {
            self.draw()
        }
        
        func draw(now: Bool = false) {
            // формат
            let format = UIGraphicsImageRendererFormat(for: self.traitCollection)
            
            // посчитанная ранее геометрия
            let geometry = self.geometry
            
            // направление письма
            let rtl: Bool =
                UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            
            // блок отрисовки
            let block = { [weak self] in
                // вьюха всё ещё актуальна?
                guard let self = self else {
                    return
                }
                
                // получим картику и координаты элементов
                var coordinates: Geometry.Coordinates = .empty
                
                let image =
                    UIGraphicsImageRenderer(size: geometry.size, format: format)
                        .image(actions: { context in
                            coordinates = geometry.draw(with: context.cgContext, rtl: rtl)
                        })
                
                // результаты
                let publish = {
                    // ещё не успело поменяться?
                    guard geometry.size == self.bounds.size.ceiled() else {
                        // геометрия уже изменилась, не надо рисовать
                        return
                    }
                    
                    // рисуем
                    self.layer.contents = image.cgImage
                    self.coordinates = coordinates
                }
                // поставим
                if now {
                    publish()
                } else {
                    DispatchQueue.main.async(execute: publish)
                }
            }
            
            // надо прямща?
            if now {
                // прямща
                block()
            } else {
                // поставим в очередь
                self.queue.async(execute: block)
            }
        }
        
        // MARK: - Геометрия
        
        override var frame: CGRect {
            didSet {
                if  self.frame.width > 0,
                    self.frame.height > 0,
                    self.frame.size != oldValue.size
                {
                    self.updateGeometry(for: self.bounds.size)
                    self.update()
                }
            }
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            self.updateGeometry(for: size)
            return self.geometry.size
        }
        
        var geometry: Geometry = .zero
        
        private func updateGeometry(for size: CGSize) {
            if self.geometry.reference != size {
                self.geometry =
                    Geometry(
                        info: self.info,
                        date: self.date,
                        size: size,
                        traits: self.traitCollection
                    )
            }
        }
        
        // MARK: - Оформление
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.updateGeometry(for: self.bounds.size)
            self.update()
        }
    }
}

// MARK: - Геометрия

extension CalendarVC.Section.Shared.YearVC.YearView {
    struct Geometry {
        
        // MARK: - Метрики
        
        var info:           CalendarVC.Info? = nil
        var date:           Date? = nil
        let reference:      CGSize
        var size:           CGSize = .zero
        
        var monthsInYear:   Int = 0
        var yearLineHeight: CGFloat = 0
        var ratio:          CGSize = .zero
        var fontsRatio:     CGFloat = 0
        var markerRadius:   CGFloat = 0
        var monthSize:      CGSize = .zero
        var space:          CGSize = .zero
        
        var cols:           CGFloat = 0
        var rows:           CGFloat = 0
        
        // MARK: - Координаты
        
        struct Coordinates {
            var days: [Day] = []
            var titles: [Title] = []
            var months: [Month] = []
            
            struct Day {
                let date: Date
                let position: CGPoint
            }
            
            struct Title {
                let date: Date
                let frame: CGRect
            }
            
            struct Month {
                let date: Date
                let frame: CGRect
                let hole: CGRect
            }
            
            static let empty = Coordinates()
        }
        
        // MARK: - Инициализация
        
        init(
            info:   CalendarVC.Info? = nil,
            date:   Date? = nil,
            size:   CGSize = .zero,
            traits: UITraitCollection? = nil
        ) {
            // параметры
            self.info = info
            self.date = date
            self.reference = size
            
            guard
                size.width > 0 && size.height > 0,
                let date = date,
                let monthsInYear = Calendar.shared.range(of: .month, in: .year, for: date)?.count,
                let info = info,
                let traits = traits
            else {
                return
            }
            
            // календарные метрики
            self.monthsInYear = monthsInYear
            
            // метрики отображения
            let inset:          CGFloat = info.style.geometry.inset
            let isLandscape:    Bool    = size.ratio > 1
            let isWide:         Bool    = traits.horizontalSizeClass == .regular && isLandscape == true  && size.width  > 320
            let isTall:         Bool    = traits.verticalSizeClass   == .regular && isLandscape == false && size.height > 320
            let multiplier:     CGPoint = CGPoint(x: 1.4, y: 1.5)
            
            // естественный размер месяца
            let preferredMonthSize: CGSize = {
                let daysInWeek:         Int     = info.metrics.daysInWeek
                let weeksInMonth:       Int     = info.metrics.weeksInMonth
                let monthLineHeight:    CGFloat = info.style.fonts.monthMonth.lineHeight.ceiled()
                let monthXHeight:       CGFloat = info.style.fonts.monthMonth.xHeight.ceiled()
                let weekdayLineHeight:  CGFloat = info.style.fonts.yearWeekday.lineHeight.ceiled()
                let dayLineHeight:      CGFloat = info.style.fonts.monthDay.lineHeight.ceiled()
                
                return CGSize(
                    width:  CGFloat(daysInWeek) * dayLineHeight * multiplier.x,
                    height: monthLineHeight + monthXHeight + weekdayLineHeight + CGFloat(weeksInMonth) * dayLineHeight * multiplier.y
                )
                .ceiled()
            }()
            
            // размерность сетки
            self.cols = isWide ? 4 : 3
            self.rows = (CGFloat(monthsInYear) / self.cols).rounded(.up)
            
            // количество пробелов
            let spacesX: CGFloat = self.cols + 1
            let spacesY: CGFloat = self.rows + 0.5
            
            // высота метки года
            self.yearLineHeight =
                info.style.fonts.yearYear.lineHeight
            
            // минимальный размер месяца
            let fittedMonthSize =
                CGSize(
                    width:  (size.width  - spacesX * inset) / self.cols,
                    height: (size.height - spacesY * inset - self.yearLineHeight) / self.rows
                )
            
            // коэффициент горизонтального сжатия плашек месяцев
            let ratioWidth: CGFloat =
                min(1, fittedMonthSize.width / preferredMonthSize.width)
            
            // коэффициент вертикального сжатия плашек месяцев
            let ratioHeight: CGFloat
            
            if (isWide || isTall) && (fittedMonthSize.height / preferredMonthSize.height >= 0.75) {
                // фрейм достаточно высок, чтобы впихнуть в него год целиком с минимальными инсетами
                ratioHeight = (size.height - inset * spacesY) / (self.yearLineHeight + preferredMonthSize.height * self.rows)
            } else {
                // не влезет, сжимаем так же, как по ширине
                ratioHeight = ratioWidth
            }
            
            self.ratio =
                CGSize(
                    width:  ratioWidth,
                    height: min(ratioWidth, ratioHeight)
                )
            
            // сжатие шрифтов
            self.fontsRatio =
                min(self.ratio.width, self.ratio.height)
                    .elastic(min: 1, max: 1, span: 0.75)
            
            // диаметр маркера текущего дня
            let dayFont:            UIFont  = info.style.fonts.monthDay.scaled(by: fontsRatio)
            let dayLineHeight:      CGFloat = dayFont.lineHeight
            
            self.markerRadius =
                dayLineHeight * 0.7
            
            // итоговый размер плашки месяца
            self.monthSize =
                CGSize(
                    width:  preferredMonthSize.width  * self.ratio.width,
                    height: preferredMonthSize.height * self.ratio.height
                )
            
            // отступы
            self.space =
                CGSize(
                    width:  max(inset / 2, min(inset * 2, (size.width  - self.monthSize.width  * self.cols) / spacesX)),
                    height: max(inset / 2, min(inset * 2, (size.height - self.monthSize.height * self.rows - self.yearLineHeight * self.ratio.height) / spacesY))
                )
            
            // общий размер
            let height: CGFloat =
                // отступ перед строкой года
                self.space.height +
                
                // строка года
                self.yearLineHeight * self.ratio.height +
                
                // отступ после строки года
                self.space.height * 0.5 +
                
                // высота сетки месяцев
                self.rows * self.monthSize.height + (self.rows - 1) * self.space.height
            
            self.size =
                CGSize(
                    width:  size.width,
                    height: height
                )
                .ceiled()
        }
        
        static let zero = Geometry()
        
        // MARK: - Отрисовка
        
        func draw(with ctx: CGContext, rtl: Bool) -> Coordinates {
            guard
                let info = self.info,
                let startOfYear = self.date
            else {
                return .empty
            }
            
            // сейчас
            let now = Date()
            
            // горизонтальные отступы
            let insetX: CGFloat =
                (self.size.width - self.monthSize.width  * self.cols - self.space.width * (self.cols - 1)) / 2
            
            // метка года
            let yearFont: UIFont =
                info.style.fonts.yearYear.scaled(by: self.ratio.height)
            
            let yearString =
                info.formatters.year.string(from: startOfYear) as NSString
            
            yearString.draw(
                with: CGRect(
                    x:      insetX,
                    y:      self.space.height,
                    width:  self.size.width - insetX * 2,
                    height: yearFont.lineHeight
                ),
                options: [.usesLineFragmentOrigin],
                attributes: [
                    .font: yearFont,
                    .foregroundColor: startOfYear.isEqual(to: now, precision: .year) ? info.style.colors.tint : info.style.colors.primary
                ],
                context: nil
            )
            
            // линейка
            ctx.setFillColor(info.style.colors.separator.cgColor)
            ctx.fill(
                CGRect(
                    x:      insetX,
                    y:      self.space.height + self.yearLineHeight * self.ratio.height,
                    width:  self.size.width - insetX * 2,
                    height: 1 / UIScreen.main.scale
                )
            )
            
            // метрики сетки
            let y:                  CGFloat = self.space.height + self.yearLineHeight * self.ratio.height + self.space.height * 0.5
            let fontsRatio:         CGFloat = self.fontsRatio
            let isCompressed:       Bool    = self.ratio.height < 0.75
            
            let daysInWeek:         Int     = info.metrics.daysInWeek
            let weeksInMonth:       Int     = info.metrics.weeksInMonth
            let firstWeekday:       Int     = info.metrics.firstWeekday
            
            let monthFont:          UIFont  = info.style.fonts.monthMonth.scaled(by: fontsRatio)
            let weekdayFont:        UIFont  = info.style.fonts.yearWeekday.scaled(by: fontsRatio)
            let dayFont:            UIFont  = info.style.fonts.monthDay.scaled(by: fontsRatio)
            
            let monthLineHeight:    CGFloat = monthFont.lineHeight
            let monthXHeight:       CGFloat = monthFont.xHeight
            let weekdayLineHeight:  CGFloat = weekdayFont.lineHeight
            let dayLineHeight:      CGFloat = dayFont.lineHeight
            
            let spaceX:             CGFloat = self.monthSize.width / CGFloat(daysInWeek)
            let monthInset:         CGFloat = spaceX / 2 - weekdayLineHeight / 4
            
            let weekdaySymbols: [String] =
                info.formatters.day.veryShortStandaloneWeekdaySymbols
            
            let weekdayRange: Range<Int> =
                Calendar.shared.maximumRange(of: .weekday) ?? 1..<8
            
            let dayWidth: CGFloat =
                (self.monthSize.width - monthInset * 2) / CGFloat(info.metrics.daysInWeek)
            
            let dayParagraph: NSParagraphStyle = {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                return paragraph
            }()
            
            let weekdayAttributes: [NSAttributedString.Key: Any] = [
                .font: weekdayFont,
                .foregroundColor: info.style.colors.primary,
                .paragraphStyle: dayParagraph,
            ]
            
            // координаты дней и заголовков месяца
            var coordinates: Coordinates = .empty
            
            // нарисуем месяцы
            for monthIndex in 0..<self.monthsInYear {
                guard
                    let startOfMonth = startOfYear.adding(.month, value: monthIndex),
                    let firstWeek = Calendar.shared.range(of: .weekOfMonth, in: .month, for: startOfMonth)?.lowerBound
                else {
                    return .empty
                }
                
                // точка отсчёта
                let origin =
                    CGPoint(
                        x: CGFloat(monthIndex % Int(self.cols)) * (self.monthSize.width  + self.space.width)  + insetX,
                        y: CGFloat(monthIndex / Int(self.cols)) * (self.monthSize.height + self.space.height) + y
                    )
                    .ceiled()
                
                var shift: CGFloat = 0
                
                // метка месяца
                let monthTitleString =
                    info.formatters.month.string(from: startOfMonth).capitalized as NSString
                
                // фрейм метки месяца
                let monthTitleRect =
                    CGRect(
                        x:      origin.x + monthInset,
                        y:      origin.y + shift,
                        width:  self.monthSize.width - monthInset * 2,
                        height: monthFont.lineHeight
                    )
                    .flip(if: rtl, with: self.size.width)
                    .ceiled()
                
                // сохраним для анимации
                coordinates.titles.append(Coordinates.Title(date: startOfMonth, frame: monthTitleRect))
                
                // нарисуем метку месяца
                monthTitleString.draw(
                    with: monthTitleRect,
                    options: [.usesLineFragmentOrigin],
                    attributes: [
                        .font: monthFont,
                        .foregroundColor: startOfMonth.isEqual(to: now, precision: .month) ? info.style.colors.tint : info.style.colors.primary
                    ],
                    context: nil
                )
                
                if isCompressed {
                    shift += monthLineHeight
                } else {
                    shift += monthLineHeight + monthXHeight
                }
                
                // строка дней недели
                var hole: CGRect = .zero
                
                if isCompressed == false {
                    for weekdayIndex in 0..<info.metrics.daysInWeek {
                        let symbol =
                            weekdaySymbols[(firstWeekday + weekdayIndex - weekdayRange.lowerBound + weekdayRange.count) % weekdayRange.count] as NSString
                        
                        let rect =
                            CGRect(
                                x:      origin.x + spaceX / 2 + CGFloat(weekdayIndex) * spaceX - dayWidth / 2,
                                y:      origin.y + shift,
                                width:  dayWidth,
                                height: weekdayLineHeight
                            )
                            .flip(if: rtl, with: self.size.width)
                        
                        symbol.draw(
                            with: rect,
                            options: [.usesLineFragmentOrigin],
                            attributes: weekdayAttributes,
                            context: nil
                        )
                        
                        hole = hole.isEmpty ? rect : hole.union(rect)
                    }
                    
                    shift += weekdayLineHeight
                }
                
                // сохраним границы месяца
                let monthRect =
                    CGRect(
                        origin: origin,
                        size: self.monthSize
                    )
                    .flip(if: rtl, with: self.size.width)
                    .ceiled()
                
                coordinates.months.append(Coordinates.Month(date: startOfMonth, frame: monthRect, hole: hole))
                
                // сетка дней месяца
                guard
                    let daysInMonth: Int = Calendar.shared.range(of: .day, in: .month, for: startOfMonth)?.count
                else {
                    return .empty
                }
                
                let spaceY: CGFloat = (self.monthSize.height - shift) / CGFloat(weeksInMonth)

                for dayIndex in 0..<daysInMonth {
                    guard
                        let startOfDay = startOfMonth.adding(.day, value: dayIndex)
                    else {
                        return .empty
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
                    
                    // центр метки дня
                    let point =
                        CGPoint(
                            x: origin.x + spaceX / 2 + CGFloat(x) * spaceX,
                            y: origin.y + spaceY / 2 + CGFloat(y) * spaceY + shift
                        )
                        .flip(if: rtl, with: self.size.width)
                    
                    // сохраним для тапов и анимаций
                    coordinates.days.append(Coordinates.Day(date: startOfDay, position: point))
                    
                    // текущий день?
                    if startOfDay.isToday {
                        // ставим маркер
                        ctx.setFillColor(info.style.colors.tint.cgColor)
                        ctx.addArc(
                            center: point,
                            radius: self.markerRadius,
                            startAngle: 0,
                            endAngle: .pi * 2,
                            clockwise: true
                        )
                        ctx.fillPath()
                    }
                    
                    // метка дня
                    let dayString =
                        info.formatters.day.string(from: startOfDay) as NSString
                    
                    let dayRect =
                        CGRect(
                            x:      point.x - dayWidth / 2,
                            y:      point.y - dayLineHeight / 2,
                            width:  dayWidth,
                            height: dayLineHeight
                        )
                    
                    dayString.draw(
                        with: dayRect,
                        options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics],
                        attributes: [
                            .font: dayFont,
                            .foregroundColor: {
                                if startOfDay.isToday {
                                    return info.style.colors.inverted
                                } else {
                                    if startOfDay.isInWeekend {
                                        return info.style.colors.weekend
                                    } else {
                                        return info.style.colors.primary
                                    }
                                }
                            }(),
                            .paragraphStyle: dayParagraph,
                        ],
                        context: nil
                    )
                }
            }
            
            return coordinates
        }
    }
}

// MARK: - Анимации перехода

extension CalendarVC.Section.Shared.YearVC.YearView {
    func layout(with monthView: CalendarVC.Section.Compact.MonthVC.MonthView) -> CalendarVC.Navigator.Compact.Animations.Layout {
        // дата
        let date = self.info.date
        
        // контроллер и вьюхи года
        guard
            let monthData = self.coordinates.months.first(where: { $0.date.isEqual(to: date, precision: .month) })
        else {
            return .empty
        }
        
        // параметры
        weak var temporaryLayer: CALayer?
        
        // вернём блоки вёрстки
        return .init(
            native: .init(
                prepare: {
                    
                },
                layout: {
                    
                },
                cleanup: { success in
                    // уберём заглушку
                    temporaryLayer?.removeFromSuperlayer()
                }
            ),
            foreign: .init(
                prepare: {
                    // заглушка целевого месяца
                    let maskLayer: CALayer = {
                        let layer = CALayer()
                        layer.frame = monthData.frame
                        layer.backgroundColor = self.info.style.colors.background.cgColor
                        return layer
                    }()
                    
                    // поставим
                    self.layer.addSublayer(maskLayer)
                    
                    // дырка под строку дней недели
                    maskLayer.mask = {
                        let mask = CAShapeLayer()
                        mask.fillRule = .evenOdd
                        mask.fillColor = UIColor.black.cgColor
                        mask.path = {
                            let path = UIBezierPath(rect: maskLayer.bounds)
                            path.append(UIBezierPath(rect: maskLayer.convert(monthData.hole, from: self.layer)))
                            path.usesEvenOddFillRule = true
                            return path.cgPath
                        }()
                        return mask
                    }()
                    
                    // придержим
                    temporaryLayer = maskLayer
                },
                layout: {
                    
                },
                cleanup: { success in
                    // уберём заглушку
                    temporaryLayer?.removeFromSuperlayer()
                }
            )
        )
    }
}
