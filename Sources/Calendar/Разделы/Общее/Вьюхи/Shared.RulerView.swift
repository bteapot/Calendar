//
//  Shared.RulerView.swift
//  AUS
//
//  Created by Денис Либит on 02.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Section.Shared {
    final class RulerView<E: CALayer>: UIView {
        
        // MARK: - Инициализация
        
        required init(
            elements: [E],
            height:   CGFloat
        ) {
            // параметры
            self.elements = elements
            self.height = height
            
            // инициализируемся
            super.init(frame: .zero)
            
            // добавляем элементы
            elements.forEach(self.layer.addSublayer)
        }
        
        @available(*, unavailable)
        override init(frame: CGRect) { fatalError() }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Свойства
        
        let elements: [E]
        var height: CGFloat
        
        // MARK: - Элементы
        
        func element(at point: CGPoint) -> E? {
            guard self.bounds.contains(point) else {
                return nil
            }
            
            return self.elements
                .map { ($0, $0.position.squaredDistance(to: point)) }
                .min(by: { $0.1 < $1.1 })
                .map { $0.0 }
        }
        
        // MARK: - Геометрия
        
        override func layoutSubviews() {
            let bounds: CGRect  = self.bounds
            let space:  CGFloat = bounds.width / CGFloat(self.elements.count)
            
            self.elements
                .enumerated()
                .forEach { index, element in
                    element.bounds.size =
                        element.preferredFrameSize()
                    
                    element.position =
                        CGPoint(
                            x: space * 0.5 + CGFloat(index) * space,
                            y: bounds.height / 2
                        )
                }
            
            // rtl
            self.layer.flipLayoutIfNeeded()
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(
                width:  size.width,
                height: self.height
            )
        }
    }
}
