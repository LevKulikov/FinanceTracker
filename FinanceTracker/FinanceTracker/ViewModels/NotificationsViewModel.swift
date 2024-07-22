//
//  NotificationsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.07.2024.
//

import Foundation
import SwiftUI

final class NotificationsViewModel: ObservableObject {
    //MARK: - Properties
    
    //MARK: Published props
    
    //MARK: Private props
    private let notificationManager: any NotificationManagerProtocol
    
    //MARK: - Initializer
    init(notificationManager: some NotificationManagerProtocol) {
        self.notificationManager = notificationManager
    }
    
    //MARK: - Methods
    
    //MARK: Private props
    
}
