//
//  MonthVC.swift
//  Calendar
//
//  Created by Денис Либит on 19.04.2021.
//

import Foundation
import UIKit
import ReactiveSwift
import InfiniteScrollView


extension CalendarVC.Section.Regular {
    final class MonthVC: UIViewController, RegularSectionProtocol {
        
        // MARK: - Инициализация
        
        required init(_ info: CalendarVC.Info) {
            // параметры
            self.info = info
            
            // инициализируемся
            super.init(nibName: nil, bundle: nil)
            
            // настроим навбар
            self.navigationItem.setup()
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Протокол Section
        
        var kind: CalendarVC.Section.Kind = .month
        let info: CalendarVC.Info
        
        func reload() {
            
        }
        
        func update() {
            
        }
        
        func scroll(to date: Date, animated: Bool) {
            
        }
        
        lazy var display: Property<(Date?, Bool)> =
            Property(
                initial: self.info.date,
                then: self.info.interaction.shown.output.map(\.1)
            )
            .map { ($0, true) }
        
        lazy var ruler: CalendarVC.Navigator.Ruler? = nil
        
        override func viewDidLoad() {
            self.view.backgroundColor = self.info.style.colors.background
        }
    }
}
