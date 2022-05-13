//
//  CGFloat+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 27.07.2020.
//

import CoreGraphics


public extension CGFloat {
    func floored() -> CGFloat {
        return floor(self)
    }

    func ceiled()  -> CGFloat {
        return ceil(self)
    }

    func min(_ value: CGFloat) -> CGFloat {
        return Swift.min(self, value)
    }

    func max(_ value: CGFloat) -> CGFloat {
        return Swift.max(self, value)
    }

    /// Эффект rubber band.
    /// - Parameters:
    ///   - min: Нижняя граница, за которой начинает действовать эффект.
    ///   - max: Верхняя граница, за которой начинает действовать эффект.
    ///   - span: Максимальный размер растяжения от границ.
    /// - Returns: Исходное значение, если оно лежит в указанных границах, или скорректированное с учётом эффекта растяжения.
    func elastic(
        min:  CGFloat = -.greatestFiniteMagnitude,
        max:  CGFloat = .greatestFiniteMagnitude,
        span: CGFloat = 44
    ) -> CGFloat {
        if self < min {
            return min - span * tanh((min - self) / span)
        }

        if self > max {
            return max + span * tanh((self - max) / span)
        }

        return self
    }
}
