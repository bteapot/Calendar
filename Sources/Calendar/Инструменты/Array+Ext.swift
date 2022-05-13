//
//  Array+Ext.swift
//  Calendar
//
//  Created by Денис Либит on 12.11.2020.
//

extension Array: Comparable where Element: Comparable {
    public static func < (lhs: [Element], rhs: [Element]) -> Bool {
        if lhs.count != rhs.count {
            return lhs.count < rhs.count
        }

        return zip(lhs, rhs).contains(where: { $0.0 < $0.1 })
    }
}
