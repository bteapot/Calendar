//
//  CalendarEventProtocol.swift
//  Calendar
//
//  Created by Денис Либит on 15.04.2021.
//

import Foundation
import UIKit


public protocol CalendarEventProtocol {
    var title: String { get set }
    var location: String? { get set }
    
    var creationDate: Date? { get }
    var lastModifiedDate: Date? { get }
    var timeZone: TimeZone? { get set }
    var url: URL? { get set }
    
    var interval: DateInterval { get set }
    var isAllDay: Bool { get set }
    
    var color: CGColor { get }
    
    var isReadonly: Bool { get }
    
    func isEqual(to other: CalendarEventProtocol) -> Bool
}
