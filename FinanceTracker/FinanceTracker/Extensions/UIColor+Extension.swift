//
//  UIColor+Extension.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import Foundation
import UIKit

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
