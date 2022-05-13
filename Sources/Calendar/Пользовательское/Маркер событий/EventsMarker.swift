//
//  EventsMarker.swift
//  Calendar
//
//  Created by Денис Либит on 24.08.2021.
//

import Foundation
import UIKit


public protocol EventsMarkerProtocol where Self: CALayer {
    var date: Date { get set }
    
    func set(style: CalendarVC.Style)
    func set(events: [CalendarEventProtocol])
}

extension CalendarVC {
    public struct EventsMarker {}
}
