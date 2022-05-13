//
//  Navigator.Compact.Animations.MD.swift
//  Calendar
//
//  Created by Денис Либит on 15.06.2021.
//

import Foundation
import UIKit


extension CalendarVC.Navigator.Compact.Animations {
    final class MD: NSObject {
        
        init(info: CalendarVC.Info) {
            self.info = info
            super.init()
        }
        
        private let info: CalendarVC.Info
    }
}

extension CalendarVC.Navigator.Compact.Animations.MD: UIViewControllerAnimatedTransitioning {
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
            let dayVC = transitionContext.viewController(forKey: .to) as? CalendarVC.Section.Compact.DayVC,
            let dayView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        // поставим вьюху контроллера года в нативное положение
        dayView.frame = transitionContext.finalFrame(for: dayVC)
        containerView.insertSubview(dayView, at: 0)
        dayView.layoutIfNeeded()
        
        // запускаем
        CalendarVC.Navigator.Compact.Animations.execute(
            context:  transitionContext,
            duration: transitionDuration,
            from:     monthVC.layout(with: dayVC),
            to:       dayVC.layout(with: monthVC)
        )
    }
}
