//
//  Selection.swift
//  Calendar
//
//  Created by Денис Либит on 27.05.2021.
//

import Foundation
import UIKit
import ReactiveSwift


extension CalendarVC {
    public final class Selection {
        public typealias Closure = (CalendarVC, CalendarEventProtocol, UIView, @escaping () -> Void) -> Void
        
        init(_ closure: @escaping Closure) {
            self.closure = closure
        }
        
        weak var controller: CalendarVC?
        
        public var event: CalendarEventProtocol? { self.property.value }
        public lazy var producer = self.property.producer
        
        private let closure: Closure
        private let property = MutableProperty<CalendarEventProtocol?>(nil)
        
        public func select(_ eventInfo: DayViewProtocol.EventInfo) {
            guard let controller = self.controller else {
                #if DEBUG
                fatalError()
                #else
                return
                #endif
            }
            
            // событие уже выбрано?
            if  let event = self.event,
                eventInfo.event.isEqual(to: event)
            {
                return
            }
            
            // поставим выбранное
            self.property.value = eventInfo.event
            
            // отреагируем
            self.closure(controller, eventInfo.event, eventInfo.view) {
                self.deselect()
            }
        }
        
        public func deselect() {
            self.property.value = nil
        }
        
        public static func custom(_ closure: @escaping Closure) -> Selection {
            .init(closure)
        }
    }
}
