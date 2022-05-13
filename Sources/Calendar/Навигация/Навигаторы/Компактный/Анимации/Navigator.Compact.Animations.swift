//
//  Navigator.Compact.Animations.swift
//  Calendar
//
//  Created by Денис Либит on 07.06.2021.
//

import Foundation
import UIKit

extension CalendarVC.Navigator.Compact {
    struct Animations {}
}

extension CalendarVC.Navigator.Compact.Animations {
    struct Layout {
        let native:  Blocks
        let foreign: Blocks
    }
}

extension CalendarVC.Navigator.Compact.Animations.Layout {
    struct Blocks {
        let prepare: () -> Void
        let layout:  () -> Void
        let cleanup: (Bool) -> Void
    }
}

extension CalendarVC.Navigator.Compact.Animations.Layout {
    static let empty = Self(native: .empty, foreign: .empty)
}

extension CalendarVC.Navigator.Compact.Animations.Layout.Blocks {
    static let empty = Self(prepare: {}, layout: {}, cleanup: { _ in })
}

extension CalendarVC.Navigator.Compact.Animations {
    static func execute(
        context: UIViewControllerContextTransitioning,
        duration: TimeInterval,
        from: Layout,
        to: Layout
    ) {
        self.unanimated {
            from.foreign.prepare()
            to.foreign.prepare()
            to.foreign.layout()
            to.native.prepare()
        } completion: {
            self.animated(duration: duration) {
                from.foreign.layout()
                to.native.layout()
            } completion: {
                self.unanimated {
                    // результат
                    let success: Bool = context.transitionWasCancelled == false
                    
                    // зачистим
                    from.foreign.cleanup(success)
                    
                    // удачно?
                    if success {
                        // удачно, зачистим конечный
                        to.native.cleanup(true)
                    } else {
                        // неудачно, уберём вьюху конечного
                        context.view(forKey: .to)?.removeFromSuperview()
                    }
                    
                    context.completeTransition(success)
                } completion: {
                    
                }
            }
        }
    }
    
    private static func unanimated(animations: () -> Void, completion: (() -> Void)?) {
        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.setCompletionBlock(completion)
            animations()
            CATransaction.commit()
        }
    }
    
    private static func animated(duration: TimeInterval, animations: @escaping () -> Void, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .default))
        CATransaction.setCompletionBlock(completion)
        
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: duration,
            delay: 0,
            options: [],
            animations: animations,
            completion: nil
        )
        
        CATransaction.commit()
    }
}
