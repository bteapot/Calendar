//
//  UIApplication+Reactive.swift
//  Calendar
//
//  Created by Денис Либит on 12.09.2020.
//

import Foundation
import UIKit
import ReactiveSwift
import ReactiveCocoa


extension Reactive where Base: UIApplication {
    var isActive: Property<Bool> {
        return .init(
            initial: self.base.applicationState == .active,
            then: Signal
                .merge(
                    NotificationCenter.default.reactive.notifications(forName: UIApplication.didBecomeActiveNotification,  object: self.base).map(value: true),
                    NotificationCenter.default.reactive.notifications(forName: UIApplication.willResignActiveNotification, object: self.base).map(value: false)
                )
                .take(during: self.lifetime)
        )
    }
}
