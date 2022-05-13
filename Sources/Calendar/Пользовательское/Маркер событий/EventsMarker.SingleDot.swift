//
//  EventsMarker.SingleDot.swift
//  Calendar
//
//  Created by Денис Либит on 24.08.2021.
//

import Foundation
import UIKit


extension CalendarVC.EventsMarker {
    public final class SingleDot: CALayer, EventsMarkerProtocol {
        
        // MARK: - Инициализация
        
        override init() {
            super.init()
            self.addSublayer(self.mark)
        }
        
        override init(layer: Any) {
            super.init(layer: layer)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Протокол
        
        public var date: Date = .distantFuture
        
        public func set(style: CalendarVC.Style) {
            self.mark.backgroundColor = style.colors.separator.cgColor
        }
        
        public func set(events: [CalendarEventProtocol]) {
            self.isHidden = events.isEmpty
        }
        
        // MARK: - Саблэера
        
        private let mark: CALayer = {
            let layer = CALayer()
            layer.masksToBounds = true
            return layer
        }()
        
        // MARK: - Геометрия
        
        public override func layoutSublayers() {
            let bounds:     CGRect  = self.bounds
            let diameter:   CGFloat = 8
            
            self.mark.bounds.size  = CGSize.square(diameter)
            self.mark.cornerRadius = diameter / 2
            self.mark.position = bounds.center
        }
    }
}
