//
//  Compact.DayVC.Toolbar.swift
//  Calendar
//
//  Created by Денис Либит on 02.06.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


extension CalendarVC.Section.Compact.DayVC {
    final class Toolbar: ToolbarView {
        
        // MARK: - Инициализация
        
        init(
            info:       CalendarVC.Info,
            dataSource: InfiniteScrollViewDataSource
        ) {
            // параметры
            self.info = info
            
            // рулер
            self.scrollView =
                InfiniteScrollView(
                    frame: .zero,
                    direction: .horizontal,
                    dataSource: dataSource
                )
            self.scrollView.isPagingEnabled = true

            // инициализируемся
            super.init(
                frame:     .zero,
                separator: .bottom,
                effect:    info.style.navbar.translucent ? .prominent : nil,
                color:     info.style.navbar.background
            )
            
            // добавим сабвьюхи
            self.addSubview(self.weekdayRuler)
            self.addSubview(self.scrollView)
            self.addSubview(self.periodLabel)
        }
        
        @available(*, unavailable)
        required init(frame: CGRect, separator: ToolbarView.Separator, effect: UIBlurEffect.Style?, color: UIColor) { fatalError() }
        
        // MARK: - Свойства
        
        private let info: CalendarVC.Info
        
        // MARK: - Сабвьюхи
        
        private lazy var weekdayRuler =
            CalendarVC.Section.Shared.RulerView<CATextLayer>(
                elements: Array(0..<self.info.metrics.daysInWeek)
                    .map { index in
                        let layer = CATextLayer()
                        layer.contentsScale = UIScreen.main.scale
                        layer.alignmentMode = .center
                        return layer
                    },
                height: self.info.style.fonts.dayRulerWeekday.lineHeight + self.info.style.geometry.inset
            )
        
        let scrollView: InfiniteScrollView
        
        lazy var periodLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.textAlignment = .center
            return label
        }()
        
        // MARK: - Данные
        
        func update() {
            self.updateWeekdayRuler()
            self.updateScrollView()
            self.updatePeriod()
        }
        
        private func updateWeekdayRuler() {
            let firstWeekday: Int =
                self.info.metrics.firstWeekday
            
            let weekends: IndexSet =
                self.info.metrics.weekends
            
            let weekdayRange: Range<Int> =
                Calendar.shared.maximumRange(of: .weekday) ?? 1..<8
            
            let weekdaySymbols: [String] =
                self.info.formatters.day.shortStandaloneWeekdaySymbols
                
            self.weekdayRuler.elements
                .enumerated()
                .forEach { weekdayIndex, layer in
                    let symbol: String =
                        weekdaySymbols[(firstWeekday + weekdayIndex - weekdayRange.lowerBound + weekdayRange.count) % weekdayRange.count]
                    
                    layer.string =
                        NSAttributedString(
                            string: symbol,
                            attributes: [
                                .font: self.info.style.fonts.dayRulerWeekday,
                                .foregroundColor: weekends.contains(weekdayRange.lowerBound + weekdayIndex) ? self.info.style.navbar.weekend : self.info.style.navbar.primary,
                            ]
                        )
                    
                    layer.setNeedsDisplay()
                }
            
            self.weekdayRuler.height =
                self.info.style.fonts.dayRulerWeekday.lineHeight + self.info.style.geometry.inset
        }
        
        private func updateScrollView() {
            self.scrollView.items
                .forEach { item in
                    if let view = item.view as? CalendarVC.Section.Shared.RulerView<WeekdayLayer> {
                        view.elements.forEach { $0.update() }
                    }
                }
        }
        
        private func updatePeriod() {
            // обновим метку периода
            let string = self.info.formatters.full.string(from: self.info.date)
            
            let text =
                NSAttributedString(
                    string: string.prefix(1).capitalized + string.dropFirst(),
                    attributes: [
                        .font: self.info.style.fonts.compactPeriod,
                        .foregroundColor: self.info.style.navbar.primary,
                    ]
                )
            
            // меняем?
            guard self.periodLabel.attributedText?.isEqual(to: text) ?? false == false else {
                return
            }
            
            self.periodLabel.alpha = 0
            self.periodLabel.attributedText = text
            
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    self.periodLabel.alpha = 1
                }
            )
        }
        
        // MARK: - Геометрия
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let bounds:         CGRect  = self.bounds
            let insetted:       CGRect  = bounds.inset(by: self.safeAreaInsets)
            let inset:          CGFloat = self.info.style.geometry.inset
            let periodHeight:   CGFloat = self.info.style.fonts.compactPeriod.lineHeight.ceiled()
            
            self.weekdayRuler.frame =
                CGRect(
                    x:      insetted.minX,
                    y:      insetted.minY + inset / 2,
                    width:  insetted.width,
                    height: self.weekdayRuler.height
                )
            
            self.scrollView.frame =
                CGRect(
                    x:      0,
                    y:      self.weekdayRuler.frame.maxY,
                    width:  bounds.width,
                    height: WeekdayLayer.height(with: self.info)
                )
            
            self.periodLabel.frame =
                CGRect(
                    x:      insetted.minX + inset,
                    y:      self.scrollView.frame.maxY + inset / 2,
                    width:  insetted.width - inset * 2,
                    height: periodHeight
                )
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let inset:              CGFloat = self.info.style.geometry.inset
            let weekdayRulerHeight: CGFloat = self.weekdayRuler.height
            let scrollViewHeight:   CGFloat = WeekdayLayer.height(with: self.info)
            let periodHeight:       CGFloat = self.info.style.fonts.compactPeriod.lineHeight.ceiled()

            return CGSize(
                width:  size.width,
                height: ceil(inset / 2 + weekdayRulerHeight + scrollViewHeight + inset / 2 + periodHeight + inset / 2)
            )
        }
    }
}
