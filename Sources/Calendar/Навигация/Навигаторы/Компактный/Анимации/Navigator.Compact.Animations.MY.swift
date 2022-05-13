//
//  Navigator.Compact.Animations.MY.swift
//  Calendar
//
//  Created by Денис Либит on 11.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Navigator.Compact.Animations {
    final class MY: NSObject {
        
        init(info: CalendarVC.Info) {
            self.info = info
            super.init()
        }
        
        private let info: CalendarVC.Info
    }
}

extension CalendarVC.Navigator.Compact.Animations.MY: UIViewControllerAnimatedTransitioning {
    final func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    final func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // анимируем?
        guard transitionContext.isAnimated == true else {
            transitionContext.completeTransition(true)
            return
        }
        
        // продолжительность анимации
        let transitionDuration: TimeInterval =
            self.transitionDuration(using: transitionContext)
        
        // контейнер
        let containerView =
            transitionContext.containerView
        
        // поставим фон
        containerView.backgroundColor =
            self.info.style.colors.background
        
        // контроллеры и вьюхи
        guard
            let monthVC = transitionContext.viewController(forKey: .from) as? CalendarVC.Section.Compact.MonthVC,
            let calendarVC = transitionContext.viewController(forKey: .to) as? CalendarVC,
            let calendarView = transitionContext.view(forKey: .to),
            let yearVC = calendarVC.children.first as? CalendarVC.Section.Shared.YearVC
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        // поставим вьюху контроллера года в нативное положение
        calendarView.frame = transitionContext.finalFrame(for: calendarVC)
        containerView.insertSubview(calendarView, at: 0)
        calendarView.layoutIfNeeded()
        
        // запускаем
        CalendarVC.Navigator.Compact.Animations.execute(
            context:  transitionContext,
            duration: transitionDuration,
            from:     monthVC.layout(with: yearVC),
            to:       calendarVC.layout(with: monthVC)
        )
    }
}
