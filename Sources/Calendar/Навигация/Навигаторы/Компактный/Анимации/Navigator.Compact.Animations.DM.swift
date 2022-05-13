//
//  Navigator.Compact.Animations.DM.swift
//  Calendar
//
//  Created by Денис Либит on 16.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Navigator.Compact.Animations {
    final class DM: NSObject {
        
        init(info: CalendarVC.Info) {
            self.info = info
            super.init()
        }
        
        private let info: CalendarVC.Info
    }
}

extension CalendarVC.Navigator.Compact.Animations.DM: UIViewControllerAnimatedTransitioning {
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
            let dayVC = transitionContext.viewController(forKey: .from) as? CalendarVC.Section.Compact.DayVC,
            let monthVC = transitionContext.viewController(forKey: .to) as? CalendarVC.Section.Compact.MonthVC,
            let monthView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        // поставим вьюху контроллера года в нативное положение
        monthView.frame = transitionContext.finalFrame(for: monthVC)
        containerView.addSubview(monthView)
        monthView.layoutIfNeeded()
        
        // запускаем
        CalendarVC.Navigator.Compact.Animations.execute(
            context:  transitionContext,
            duration: transitionDuration,
            from:     dayVC.layout(with: monthVC),
            to:       monthVC.layout(with: dayVC)
        )
    }
}
