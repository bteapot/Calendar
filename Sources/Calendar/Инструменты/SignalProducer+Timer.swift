//
//  SignalProducer+Timer.swift
//  Calendar
//
//  Created by Денис Либит on 03.02.2021.
//

import Foundation
import UIKit
import ReactiveSwift


extension SignalProducer where Value == Date, Error == Never {
    /// Таймер, встающий на паузу во время нахождения приложения в фоне.
    ///
    /// - parameters:
    ///   - after: Опционально, дата первого срабатывания таймера.
    ///   - interval: Интервал срабатывания таймера в секундах.
    ///   - scheduler: Шедулер, на котором будет крутится таймер.
    ///
    /// - precondition: Вызов функции должен быть выполнен из главного потока, так как используется API `UIApplication`.
    ///
    /// - returns: Продюсер, присылающий `Date` каждые `interval` секунд, если приложение активно.
    static func autopausedTimer(
        after: Date? = nil,
        interval: Int,
        on scheduler: QueueScheduler
    ) -> SignalProducer<Value, Error> {
        precondition(Thread.isMainThread)
        
        // дата последнего срабатывания, изначально – давным-давно
        var last: Date = .distantPast
        
        // соберём логику
        return UIApplication.shared.reactive.isActive
            .producer
            .flatMap(.latest) { isActive in
                // приложение в фоне?
                if isActive == false {
                    return .never
                }
                
                // приложение активно, запускаем таймер
                return SignalProducer { observer, lifetime in
                    lifetime += scheduler.schedule(
                        after: {
                            // указано пользователем?
                            if let date = after {
                                return date
                            }
                            
                            // текущая дата
                            let now = scheduler.currentDate
                            
                            // дельта от даты следующего срабатывания
                            let delta: TimeInterval = last.timeIntervalSinceReferenceDate + TimeInterval(interval) - now.timeIntervalSinceReferenceDate
                            
                            return now + max(0, delta)
                        }(),
                        interval: .seconds(interval),
                        action: {
                            last = scheduler.currentDate
                            observer.send(value: last)
                        }
                    )
                }
            }
    }
}
