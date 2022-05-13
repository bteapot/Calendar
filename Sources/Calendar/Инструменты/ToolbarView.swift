//
//  ToolbarView.swift
//  Calendar
//
//  Created by Денис Либит on 30.04.2021.
//

import Foundation
import UIKit


open class ToolbarView: UIView {
    
    // MARK: - Инициализация
    
    public required init(
        frame: CGRect,
        separator: Separator,
        effect: UIBlurEffect.Style? = .prominent,
        color: UIColor = .clear
    ) {
        // параметры
        self.separator = separator
        self.blurEffect = UIBlurEffect(style: effect ?? .prominent)
        
        // инициализируемся
        super.init(frame: frame)
        
        // внешний вид
        if effect != nil {
            // полупрозрачный
            self.addSubview(self.blurView)
            self.vibrancyView.backgroundColor = color
        } else {
            // непрозрачный
            self.backgroundColor = color
        }
        
        if separator != .none {
            self.addSubview(self.separatorView)
        }
    }
    
    public convenience override init(frame: CGRect) {
        self.init(frame: frame, separator: .none)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Интерфейс
    
    public enum Separator {
        case none
        case top
        case bottom
    }
    
    public var contentView: UIView {
        if self.blurView.superview != nil {
            // полупрозрачный
            return self.vibrancyView.contentView
        } else {
            // непрозрачный
            return self
        }
    }
    
    // MARK: - Свойства
    
    private let separator: Separator
    
    // MARK: - Компоненты
    
    private lazy var separatorView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .separator
        return view
    }()
    
    private let blurEffect: UIBlurEffect
    
    private lazy var vibrancyView =
        UIVisualEffectView(
            effect: UIVibrancyEffect(
                blurEffect: self.blurEffect,
                style: .label
            )
        )
    
    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: self.blurEffect)
        view.contentView.addSubview(self.vibrancyView)
        return view
    }()
    
    // MARK: - Геометрия
    
    open override func layoutSubviews() {
        let bounds:     CGRect  = self.bounds
        let thickness:  CGFloat = 1 / UIScreen.main.scale
        
        // размытие
        self.blurView.frame = bounds
        self.vibrancyView.frame = self.blurView.bounds
        
        // разделитель
        self.separatorView.frame =
            CGRect(
                x:      0,
                y:      self.separator == .top ? 0 : bounds.height - thickness,
                width:  bounds.width,
                height: thickness
            )
        
    }
}
