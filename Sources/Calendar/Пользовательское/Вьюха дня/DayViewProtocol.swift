//
//  DayView.swift
//  Calendar
//
//  Created by Денис Либит on 24.08.2021.
//

import Foundation
import UIKit
import ReactiveSwift


public protocol DayViewProtocol where Self: UIView {
    
    typealias EventInfo = (event: CalendarEventProtocol, view: UIView)
    
    init(
        info:   CalendarVC.Info,
        date:   Date,
        offset: CGFloat,
        input:  Signal<(DayViewProtocol, CGFloat), Never>.Observer
    )
    
    static var standardSelection: Bool { get }
    
    var date: Date { get }
    
    func update()
    func set(offset: CGFloat)
    func scrollToNowIfToday(animated: Bool)
    func eventInfos(at point: CGPoint) -> [EventInfo]
}
