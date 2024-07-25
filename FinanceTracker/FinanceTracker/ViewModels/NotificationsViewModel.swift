//
//  NotificationsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.07.2024.
//

import Foundation
import SwiftUI

final class NotificationsViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    var isSystemAllowsNotifications: Bool {
        notificationManager.isSystemAllowsNotifications
    }
    
    //MARK: Published props
    @Published var notificationsIsEnabled: Bool {
        didSet {
            if notificationsIsEnabled {
                enableNotifications()
            } else {
                disableNotifications()
            }
        }
    }
    @Published var notificationTitle: String
    @Published var notificationBody: String
    @Published var notificationTime: Date {
        didSet {
            saveNotificationTime()
        }
    }
    
    //MARK: Private props
    private let notificationManager: any NotificationManagerProtocol
    
    //MARK: - Initializer
    init(notificationManager: some NotificationManagerProtocol) {
        self.notificationManager = notificationManager
        notificationsIsEnabled = notificationManager.isNotificationsAllowedByUser
        notificationTitle = notificationManager.notificationTitle
        notificationBody = notificationManager.notificationBody
        notificationTime = notificationManager.notificationTime
    }
    
    //MARK: - Methods
    func saveNotificationTitle() {
        notificationManager.setNotificationTitle(notificationTitle)
    }
    
    func saveNotificationBody() {
        notificationManager.setNotificationBody(notificationBody)
    }
    
    func saveNotificationTime() {
        notificationManager.setNotificationTime(notificationTime)
    }
    
    //MARK: Private props
    private func enableNotifications() {
        notificationManager.enableNotifications { _, status in
            switch status {
            case .authorized, .provisional:
                break
            case .denied:
                Task {
                    await MainActor.run {
                        self.notificationsIsEnabled = false
                    }
                }
            default:
                break
            }
        }
    }
    
    private func disableNotifications() {
        notificationManager.disableNotifications()
    }
}
