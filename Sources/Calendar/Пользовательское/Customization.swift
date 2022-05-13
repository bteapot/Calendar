//
//  Customization.swift
//  Calendar
//
//  Created by Денис Либит on 24.08.2021.
//

import Foundation
import UIKit


extension CalendarVC {
    public struct Customization {
        let marker:  EventsMarkerProtocol.Type
        let dayView: DayViewProtocol.Type
        let errors:  ((Error) -> Void)?
    }
}

// MARK: - Инициализация

extension CalendarVC.Customization {
    public static var none =
        Self(
            marker:  CalendarVC.EventsMarker.SingleDot.self,
            dayView: CalendarVC.Section.Shared.DayView.self,
            errors:  nil
        )
    
    public static func custom(
        marker:  EventsMarkerProtocol.Type = CalendarVC.EventsMarker.SingleDot.self,
        dayView: DayViewProtocol.Type = CalendarVC.Section.Shared.DayView.self,
        errors:  ((Error) -> Void)? = nil
    ) -> Self {
        Self(
            marker: marker,
            dayView: dayView,
            errors: errors
        )
    }
}
