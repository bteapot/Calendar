//
//  DataSource.EventKit.swift
//  Calendar
//
//  Created by Денис Либит on 15.04.2021.
//

import Foundation
import SwiftUI
import EventKit
import ReactiveSwift
import Calendar


extension CalendarVC.DataSource {
    open class EventKit: DataSourceProtocol {
        
        // MARK: - Инициализация
        
        public required init(
            _ config: Config = .all()
        ) {
            // параметры
            self.config = config
            
            // подключаем календари по готовности
            self.state
                .producer
                .filter { $0.isReady }
                .startWithValues { [weak self] _ in
                    guard let self = self else { return }
                    self.acquireSourceAndCalendar()
                }
            
            // текущее состояние
            self.updateState()
            
            // следим за изменениями хранилища
            self.changesPipe.input <~
                NotificationCenter.default.reactive.notifications(forName: .EKEventStoreChanged, object: self.store)
                    .take(during: self.binding.lifetime)
                    .map(value: ())
        }
        
        // MARK: - Свойства
        
        let store       = EKEventStore()
        let statePipe   = Signal<CalendarVC.DataSource.State, Never>.pipe()
        let changesPipe = Signal<Void, Never>.pipe()
        let errorsPipe  = Signal<Error, Never>.pipe()
        let binding     = Lifetime.make()
        
        let config:    Config
        var calendar:  EKCalendar?
        var source:    EKSource?
        var interval:  DateInterval?
        var events:    [EventWrapper] = []
        
        // MARK: - Протокол CalendarDataSource
        
        public lazy var state =
            Property<CalendarVC.DataSource.State>(
                initial: .undetermined,
                then: self.statePipe.output.skipRepeats()
            )
        
        public lazy var changes =
            self.changesPipe.output
                .observe(on: QueueScheduler.main)
        
        public lazy var errors =
            self.errorsPipe.output
                .observe(on: QueueScheduler.main)
        
        public func events(in interval: DateInterval) -> SignalProducer<[CalendarEventProtocol], Never> {
            return SignalProducer<[CalendarEventProtocol], Never> { [weak self] observer, lifetime in
                guard
                    lifetime.hasEnded == false,
                    let self = self,
                    let calendar = self.calendar,
                    EKEventStore.authorizationStatus(for: .event) == .authorized
                else {
                    observer.sendCompleted()
                    return
                }
                
                // тот же интервал?
                guard interval != self.interval else {
                    observer.send(value: self.events)
                    observer.sendCompleted()
                    return
                }
                
                // получим события
                let events: [EventWrapper] =
                    self.store.events(
                        matching: self.store.predicateForEvents(
                            withStart: interval.start,
                            end: interval.end,
                            calendars: self.config.isRestricted ? [calendar] : nil
                        )
                    )
                    .sorted(by: { $0.startDate < $1.startDate })
                    .map(EventWrapper.init)
                
                // запомним
                self.interval = interval
                self.events = events
                
                // отправим
                observer.send(value: events)
                observer.sendCompleted()
            }
        }
        
        public func save(event: CalendarEventProtocol) -> SignalProducer<Never, Never> {
            return .empty
        }
        
        // MARK: - Инструменты
        
        func acquireSourceAndCalendar() {
            // дебаг
            #if DEBUG
            defer {
                if let calendar = self.calendar {
                    NSLog("[calendar] ek data source \(Unmanaged.passUnretained(self).toOpaque()) using calendar: [\(calendar.source.sourceType.title)] [\(calendar.title)].")
                } else {
                    NSLog("[calendar] ek data source \(Unmanaged.passUnretained(self).toOpaque()) using calendar: nil.")
                }
            }
            #endif
            
            // указано название календаря?
            guard let calendarTitle = self.config.title else {
                // берём дефолтный
                self.calendar = self.store.defaultCalendarForNewEvents
                self.source = self.calendar?.source
                
                // всё готово
                return
            }
            
            // доступные календари
            let calendars = self.store.calendars(for: .event)
            
            // попробуем найти календарь с указанным названием
            if let calendar = calendars.first(where: { $0.title == calendarTitle }) {
                // нашли
                self.calendar = calendar
                self.source = calendar.source
                
                // всё
                return
            }
            
            // получим источник
            let sourcesByType: [EKSourceType: [EKSource]] =
                self.store.sources.reduce(into: [:]) { result, source in
                    if result[source.sourceType] == nil {
                        result[source.sourceType] = []
                    }
                    result[source.sourceType]?.append(source)
                }
            
            let preferredOrderedTypes: [EKSourceType] = [
                .calDAV,
                .exchange,
                .mobileMe,
                .local,
            ]
            
            for type in preferredOrderedTypes {
                if let source = sourcesByType[type]?.first {
                    self.source = source
                    break
                }
            }
            
            guard let source = self.source else {
                #if DEBUG
                NSLog("[calendar] ek data source \(Unmanaged.passUnretained(self).toOpaque()) can not find default source.")
                #endif
                return
            }
            
            // заведём новый календарь
            let calendar = EKCalendar(for: .event, eventStore: self.store)
            calendar.source = source
            calendar.title = calendarTitle
            
            do {
                try self.store.saveCalendar(calendar, commit: true)
            } catch {
                #if DEBUG
                NSLog("[calendar] ek data source \(Unmanaged.passUnretained(self).toOpaque()) can not create calendar: \(error).")
                #endif
                self.errorsPipe.input.send(value: error)
            }
            
            // запомним
            self.calendar = calendar
        }
        
        func updateState() {
            self.statePipe.input.send(value: {
                switch EKEventStore.authorizationStatus(for: .event) {
                case .notDetermined:
                    return .placeholder(
                        PlaceholderVC(
                            title: NSLocalizedString("Разрешить доступ к календарям", comment: "Заголовок заглушки календаря."),
                            subtitle: NSLocalizedString("Для работы этого раздела нужно разрешить приложению доступ к вашим календарям.", comment: "Пояснение заглушки календаря."),
                            button: .init(
                                title: NSLocalizedString("Разрешить доступ", comment: "Заголовок кнопки заглушки календаря."),
                                color: Color(hue: 0.33, saturation: 0.66, brightness: 0.63, opacity: 1.00),
                                action: {
                                    do {
                                        if try await self.store.requestAccess(to: .event) == true {
                                            self.statePipe.input.send(value: .ready)
                                        } else {
                                            self.updateState()
                                        }
                                    } catch {
                                        self.errorsPipe.input.send(value: error)
                                    }
                                }
                            )
                        )
                    )
                case .restricted:
                    return .placeholder(
                        PlaceholderVC(
                            title: NSLocalizedString("Доступ к календарям запрещён", comment: "Заголовок заглушки календаря."),
                            subtitle: NSLocalizedString("Доступ к календарям не может быть разрешён. Возможно, из-за действующих ограничений безопасности вроде родительского контроля.", comment: "Пояснение заглушки календаря.")
                        )
                    )
                case .denied:
                    return .placeholder(
                        PlaceholderVC(
                            title: NSLocalizedString("Доступ к календарям запрещён", comment: "Заголовок заглушки календаря."),
                            subtitle: NSLocalizedString("Чтобы разрешить доступ приложения к календарям, откройте настройки и включите переключатель в строке \"Календари\".", comment: "Пояснение заглушки календаря."),
                            button: .init(
                                title: NSLocalizedString("Открыть Настройки", comment: "Заголовок кнопки заглушки календаря."),
                                color: Color(hue: 0.33, saturation: 0.66, brightness: 0.63, opacity: 1.00),
                                action: {
                                    if  let url = await URL(string: UIApplication.openSettingsURLString),
                                        await UIApplication.shared.canOpenURL(url) == true
                                    {
                                        _ = await UIApplication.shared.open(url)
                                    }
                                }
                            )
                        )
                    )
                case .authorized:
                    return .ready
                @unknown default:
                    return .placeholder(
                        PlaceholderVC(
                            title: NSLocalizedString("Доступ к календарям запрещён", comment: "Заголовок заглушки календаря."),
                            subtitle: NSLocalizedString("Доступ к календарям не может быть разрешён. Возможно, из-за действующих ограничений безопасности вроде родительского контроля.", comment: "Пояснение заглушки календаря.")
                        )
                    )
                }
            }())
        }
    }
}

// MARK: - Конфигурация

extension CalendarVC.DataSource.EventKit {
    public enum Config {
        case all(default: String? = nil)
        case one(String)
    }
}

extension CalendarVC.DataSource.EventKit.Config {
    var title: String? {
        switch self {
        case .all(let title): return title
        case .one(let title): return title
        }
    }
    
    var isRestricted: Bool {
        switch self {
        case .all: return false
        case .one: return true
        }
    }
}

// MARK: - Дебаг

#if DEBUG
extension EKSourceType {
    var title: String {
        switch self {
        case .local:      return "local"
        case .exchange:   return "exchange"
        case .calDAV:     return "calDAV"
        case .mobileMe:   return "mobileMe"
        case .subscribed: return "subscribed"
        case .birthdays:  return "birthdays"
        @unknown default: return "unknown"
        }
    }
}
#endif
