//
//  EventView.swift
//  Calendar
//
//  Created by Денис Либит on 10.05.2021.
//

import Foundation
import UIKit


extension CalendarVC {
    final class EventView: UIView {
        
        // MARK: - Инициализация
        
        required init(
            info:  Info,
            mode:  Mode,
            event: CalendarEventProtocol
        ) {
            // параметры
            self.info  = info
            self.mode  = mode
            self.event = event
            
            // инициализируемся
            super.init(frame: .zero)
            
            // свойства
            self.layer.masksToBounds = true
            
            // поставим данные
            self.update()
            
            // добавим сабвьюхи
            self.layer.addSublayer(self.backgroundLayer)
            self.layer.addSublayer(self.handleLayer)
            self.layer.addSublayer(self.titleLayer)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Параметры
        
        enum Mode {
            case normal(handle: Bool)
            case small
        }
        
        let info:  Info
        let mode:  Mode
        
        var event: CalendarEventProtocol {
            didSet {
                self.update()
            }
        }
        
        // MARK: - Данные
        
        func update() {
            // текст
            self.titleLayer.string = self.event.title
            
            // цвет события
            let color: CGColor = self.event.color
            
            // цвет ручки
            self.handleLayer.backgroundColor = color
            
            // особенности режима
            switch self.mode {
            case .normal(let handle):
                self.layer.cornerRadius = 6
                self.handleLayer.isHidden = handle == false
                self.titleLayer.font = self.info.style.fonts.eventNormal
                self.titleLayer.fontSize = self.info.style.fonts.eventNormal.pointSize
            case .small:
                self.layer.cornerRadius = 3
                self.handleLayer.isHidden = true
                self.titleLayer.font = self.info.style.fonts.eventSmall
                self.titleLayer.fontSize = self.info.style.fonts.eventSmall.pointSize
            }
            
            // состояние выбранности
            if self.isSelected {
                // событие выбрано
                self.titleLayer.foregroundColor = color.white > 0.75 ? UIColor.darkText.cgColor : UIColor.lightText.cgColor
                self.backgroundLayer.backgroundColor = color
            } else {
                // событие не выбрано
                
                // разберём цвета
                var h: CGFloat = 0
                var s: CGFloat = 0
                var b: CGFloat = 0
                var a: CGFloat = 0
                
                if  let converted = color.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
                    UIColor(cgColor: converted).getHue(&h, saturation: &s, brightness: &b, alpha: &a) == true
                {} else {
                    h = 0
                }
                
                self.titleLayer.foregroundColor      = UIColor(hue: h, saturation: 1.00, brightness: 0.60, alpha: 1.00).cgColor
                self.backgroundLayer.backgroundColor = UIColor(hue: h, saturation: 0.20, brightness: 1.00, alpha: 1.00).cgColor
            }
        }
        
        // MARK: - Выбор
        
        var isSelected: Bool = false {
            didSet {
                self.update()
            }
        }
        
        // MARK: - Сабвьюхи
        
        private lazy var backgroundLayer: CALayer = {
            let layer = CALayer()
            layer.zPosition = 0
            layer.backgroundColor = self.event.color
            
            switch self.mode {
            case .normal(let handle) where handle == true:
                layer.opacity = 0.5
            default:
                break
            }
            
            return layer
        }()
        
        private lazy var handleLayer: CALayer = {
            let layer = CALayer()
            layer.zPosition = 1
            layer.backgroundColor = self.event.color
            return layer
        }()
        
        private lazy var titleLayer: CATextLayer = {
            let layer = CATextLayer()
            layer.zPosition = 2
            layer.anchorPoint = CGPoint(x: 0, y: 0)
            layer.contentsScale = UIScreen.main.scale
            layer.isWrapped = true
            layer.alignmentMode = .natural
            layer.truncationMode = .end
            return layer
        }()
        
        // MARK: - Геометрия
        
        override func layoutSubviews() {
            let bounds:     CGRect  = self.bounds
            let inset:      CGFloat = self.info.style.geometry.inset / 4
            
            self.backgroundLayer.frame = bounds
            
            self.handleLayer.frame =
                CGRect(
                    x:      0,
                    y:      0,
                    width:  inset,
                    height: bounds.height
                )
            
            self.titleLayer.frame =
                CGRect(
                    x:      inset * 2,
                    y:      inset,
                    width:  bounds.width  - inset * 4,
                    height: bounds.height - inset * 2
                )
            
            // rtl
            self.layer.flipLayoutIfNeeded()
        }
        
        // MARK: - Оформление
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.update()
        }
    }
}
