//
//  URL+Extension.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 09.08.2024.
//

import Foundation

extension URL: Identifiable {
    public var id: Int {
        return hashValue
    }
}
