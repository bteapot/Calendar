//
//  Navigator.Regular.Toolbar.swift
//  Calendar
//
//  Created by Денис Либит on 27.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


extension CalendarVC.Navigator.Regular {
    final class Toolbar: ToolbarView {
        
        // MARK: - Инициализация
        
        init(
            sectionTitles: [String],
            selectedIndex: Int,
            info:          CalendarVC.Info,
            delegate:      UIToolbarDelegate
        ) {
            // параметры
            self.info = info
            
            self.switcher = UISegmentedControl(items: sectionTitles)
            self.switcher.setTitleTextAttributes([.foregroundColor: info.style.colors.switcherTitleNormal], for: .normal)
            self.switcher.setTitleTextAttributes([.foregroundColor: info.style.colors.switcherTitleSelected], for: .selected)
            self.switcher.selectedSegmentIndex = selectedIndex
            
            // инициализируемся
            super.init(
                frame:     .zero,
                separator: .bottom,
                effect:    info.style.navbar.translucent ? .prominent : nil,
                color:     info.style.navbar.background
            )
            
            // добавим сабвьюхи
            self.addSubview(self.period)
            self.addSubview(self.switcher)
            self.addSubview(self.today)
        }
        
        @available(*, unavailable)
        required init(frame: CGRect, separator: ToolbarView.Separator, effect: UIBlurEffect.Style?, color: UIColor) { fatalError() }
        
        // MARK: - Свойства
        
        private let info: CalendarVC.Info
        
        // MARK: - Сабвьюхи
        
        let period: UILabel = {
            let label = UILabel(frame: .zero)
            return label
        }()
        
        let switcher: UISegmentedControl
        
        let today: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle(NSLocalizedString("Сегодня", comment: "Заголовок кнопки календаря."), for: .normal)
            return button
        }()
        
        var ruler: CalendarVC.Navigator.Ruler? {
            willSet {
                if let ruler = self.ruler {
                    ruler.view.removeFromSuperview()
                }
            }
            didSet {
                if let ruler = self.ruler {
                    self.addSubview(ruler.view)
                }
                self.setNeedsLayout()
            }
        }
        
        // MARK: - Данные
        
        func update(period: (date: Date?, month: Bool)) {
            // соберём метку периода
            let text = NSMutableAttributedString()
            
            // есть дата?
            if let date = period.date {
                // месяц?
                if period.month {
                    text.append(
                        NSAttributedString(
                            string: self.info.formatters.month.string(from: date).capitalized + " ",
                            attributes: [
                                .font: self.info.style.fonts.regularPeriodBold,
                                .foregroundColor: self.info.style.navbar.primary,
                            ]
                        )
                    )
                }
                
                // год
                text.append(
                    NSAttributedString(
                        string: self.info.formatters.year.string(from: date),
                        attributes: [
                            .font: self.info.style.fonts.regularPeriod,
                            .foregroundColor: self.info.style.navbar.primary,
                        ]
                    )
                )
            }
            
            // меняем?
            guard self.period.attributedText?.isEqual(to: text) ?? false == false else {
                return
            }
            
            UIView.animate(
                withDuration: 0.125,
                animations: {
                    self.period.alpha = 0
                },
                completion: { finished in
                    guard finished else {
                        return
                    }
                    
                    self.period.attributedText = text
                    self.setNeedsLayout()
                    
                    UIView.animate(
                        withDuration: 0.125,
                        animations: {
                            self.period.alpha = 1
                        }
                    )
                }
            )
        }
        
        // MARK: - Геометрия
        
        private let alwaysDouble: Bool = true
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let bounds:         CGRect  = self.bounds
            let safeOffset:     CGFloat = self.safeAreaInsets.top
            let inset:          CGFloat = self.info.style.geometry.inset
            let periodSize:     CGSize  = self.period.sizeThatFits(bounds.size).ceiled()
            let switcherSize:   CGSize  = self.switcher.sizeThatFits(bounds.size).ceiled()
            let todaySize:      CGSize  = self.today.sizeThatFits(bounds.size).ceiled()
            let rulerHeight:    CGFloat = self.ruler?.size(bounds.size.width).height ?? 0
            let fullWidth:      CGFloat = periodSize.width + inset + switcherSize.width + inset + todaySize.width
            
            // влезает?
            if self.alwaysDouble == false && fullWidth < bounds.width {
                // влезает, в одну строку
                let maxHeight: CGFloat = max(44, periodSize.height, switcherSize.height, todaySize.height)
                
                self.switcher.frame =
                    CGRect(
                        x:      (bounds.width - switcherSize.width) / 2,
                        y:      safeOffset + inset + (maxHeight - switcherSize.height) / 2,
                        width:  switcherSize.width,
                        height: switcherSize.height
                    )
                    .ceiled()
                
                self.period.frame =
                    CGRect(
                        x:      0,
                        y:      safeOffset + inset,
                        width:  self.switcher.frame.minX - inset,
                        height: maxHeight
                    )
                    .ceiled()
                
                self.today.frame =
                    CGRect(
                        x:      bounds.width - todaySize.width,
                        y:      safeOffset + inset,
                        width:  todaySize.width,
                        height: maxHeight
                    )
                    .ceiled()
                
                self.ruler?.view.frame =
                    CGRect(
                        x:      0,
                        y:      safeOffset + inset + maxHeight + inset / 2,
                        width:  bounds.width,
                        height: rulerHeight
                    )
                    .ceiled()
            } else {
                // не влезает, в две строки
                self.switcher.frame =
                    CGRect(
                        x:      inset,
                        y:      safeOffset + inset,
                        width:  bounds.width - inset * 2,
                        height: switcherSize.height
                    )
                    .ceiled()
                
                let maxHeight: CGFloat = max(44, periodSize.height, todaySize.height)
                
                self.today.frame =
                    CGRect(
                        x:      bounds.width - todaySize.width - inset - inset / 2,
                        y:      self.switcher.frame.maxY + inset / 2,
                        width:  todaySize.width,
                        height: maxHeight
                    )
                    .ceiled()
                
                self.period.frame =
                    CGRect(
                        x:      inset + inset / 2,
                        y:      self.switcher.frame.maxY + inset / 2,
                        width:  self.today.frame.minX - inset / 2 - inset,
                        height: maxHeight
                    )
                    .ceiled()
                
                self.ruler?.view.frame =
                    CGRect(
                        x:      0,
                        y:      self.switcher.frame.maxY + inset / 2 + maxHeight + inset / 2,
                        width:  bounds.width,
                        height: rulerHeight
                    )
                    .ceiled()
            }
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let inset:          CGFloat = self.info.style.geometry.inset
            let periodSize:     CGSize  = self.period.sizeThatFits(size).ceiled()
            let switcherSize:   CGSize  = self.switcher.sizeThatFits(size).ceiled()
            let todaySize:      CGSize  = self.today.sizeThatFits(size).ceiled()
            let rulerHeight:    CGFloat = self.ruler?.size(bounds.size.width).height ?? 0
            let fullWidth:      CGFloat = periodSize.width + inset + switcherSize.width + inset + todaySize.width
            
            // влезает?
            if self.alwaysDouble == false && fullWidth < size.width {
                // влезает, в одну строку
                return CGSize(
                    width:  size.width,
                    height: inset + max(periodSize.height, switcherSize.height, todaySize.height) + inset / 2 + rulerHeight
                )
                .ceiled()
            } else {
                // не влезает, в две строки
                return CGSize(
                    width:  size.width,
                    height: inset + switcherSize.height + inset / 2 + max(44, periodSize.height, todaySize.height) + inset / 2 + rulerHeight
                )
                .ceiled()
            }
        }
    }
}
