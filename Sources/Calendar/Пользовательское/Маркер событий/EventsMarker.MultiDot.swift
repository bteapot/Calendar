//
//  EventsMarker.MultiDot.swift
//  Calendar
//
//  Created by Денис Либит on 24.08.2021.
//

import Foundation
import UIKit


extension CalendarVC.EventsMarker {
    public final class MultiDot: CALayer, EventsMarkerProtocol {
        
        // MARK: - Протокол
        
        public var date: Date = .distantFuture
        
        public func set(style: CalendarVC.Style) {}
        
        public func set(events: [CalendarEventProtocol]) {
            // выберем цвета
            let markers: [CALayer] =
                Set(events.map({ $0.color }))
                    .sorted(
                        by: {
                            let lhs: [CGFloat] = $0.components ?? []
                            let rhs: [CGFloat] = $1.components ?? []
                            return lhs < rhs
                        }
                    )
                    .map { color in
                        return self.markers.first(where: { $0.backgroundColor == color }) ?? {
                            let layer = CALayer()
                            layer.backgroundColor = color
                            self.addSublayer(layer)
                            return layer
                        }()
                    }
            
            // уберём старые
            self.markers
                .filter { markers.contains($0) == false }
                .forEach { $0.removeFromSuperlayer() }
            
            // запомним новые
            self.markers = markers
            
            // перевёрстка
            self.setNeedsLayout()
        }
        
        // MARK: - Саблэера
        
        private var markers: [CALayer] = []
        
        // MARK: - Геометрия
        
        public override func layoutSublayers() {
            let bounds:     CGRect  = self.bounds
            let diameter:   CGFloat = 6
            let space:      CGFloat = 2
            let count:      CGFloat = CGFloat(self.markers.count)
            let x:          CGFloat = bounds.width / 2 - (count < 2 ? 0 : (diameter + space) * (count - 1) / 2)
            
            self.markers
                .enumerated()
                .forEach { index, marker in
                    marker.bounds.size  = CGSize.square(diameter)
                    marker.cornerRadius = diameter / 2
                    marker.position =
                        CGPoint(
                            x: x + CGFloat(index) * (diameter + space),
                            y: bounds.midY
                        )
                }
        }
    }
}
