//
//  NotificationManager.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 21.07.2024.
//

import Foundation
import UserNotifications

protocol NotificationManagerProtocol: AnyObject {
    /// Notifications are permited in a device settings
    var isSystemAllowsNotifications: Bool { get }
    
    /// If user wants to get notifications
    var isNotificationsAllowedByUser: Bool { get }
    
    /// Title for notifications
    var notificationTitle: String { get }
    
    /// Body text for notifications
    var notificationBody: String { get }
    
    /// Time for notifications
    var notificationTime: Date { get }
    
    /// Checks status of notification permision by a system
    func checkForSystemNotificationPermition()
    
    /// Properly enables app notifications through asking system for permition and asking user to provide permition if system provides that this setting is not determined or denied
    /// - Parameter completionHandler: Handler that is executed after notifications are permitid, parameter of this closure determines if notifications are permited or not, and what is authorization status
    func enableNotifications(completionHandler: ((Bool, UNAuthorizationStatus) -> Void)?)
    
    /// Disables notifications
    func disableNotifications()
    
    /// Sends in the queue repeatable notification with reminder
    func dispatchReminderNotification()
    
    /// Saves title for reminder norification
    /// - Parameter title: title to set for notification
    func setNotificationTitle(_ title: String)
    
    /// Saves body text for reminder notification
    /// - Parameter body: string to set as body to notification
    func setNotificationBody(_ body: String)
    
    /// Saves time for notification
    /// - Parameter time: date with set hour and minute
    func setNotificationTime(_ time: Date)
}

final class NotificationManager: NotificationManagerProtocol {
    //MARK: - Properties
    private static let shared = NotificationManager()
    
    var isSystemAllowsNotifications: Bool {
        return systemNotificationPermition ?? false
    }
    private(set) var isNotificationsAllowedByUser: Bool {
        didSet {
            UserDefaults.standard.setValue(isNotificationsAllowedByUser, forKey: isNotificationsAllowedKey)
            if isNotificationsAllowedByUser {
                dispatchReminderNotification()
            } else {
                notificationCenter.removeAllPendingNotificationRequests()
            }
        }
    }
    private(set) var notificationTitle: String
    private(set) var notificationBody: String
    private(set) var notificationTime: Date
    
    private let notificationCenter: UNUserNotificationCenter
    private let reminderNotificationIdentifier = "FTReminderNotificationIdentifier"
    private let isNotificationsAllowedKey = "isNotificationsAllowedKey"
    private let notificationTitleKey = "notificationTitleKey"
    private let notificationBodyKey = "notificationBodyKey"
    private let notificationTimeKey = "notificationTimeKey"
    private var systemNotificationPermition: Bool?
    
    //MARK: - Initializer
    init() {
        notificationCenter = UNUserNotificationCenter.current()
        isNotificationsAllowedByUser = UserDefaults.standard.value(forKey: isNotificationsAllowedKey) as? Bool ?? true
        notificationTitle = UserDefaults.standard.string(forKey: notificationTitleKey) ?? String(localized: "Finances are important")
        notificationBody = UserDefaults.standard.string(forKey: notificationBodyKey) ?? String(localized: "Don't forget to add your spendings")
        notificationTime = UserDefaults.standard.object(forKey: notificationTimeKey) as? Date ?? Calendar.current.date(from: DateComponents(hour: 20, minute: 50))!
        checkForSystemNotificationPermition()
    }
    
    //MARK: - Methods
    static func askForPermition() {
        UNUserNotificationCenter.current().requestAuthorization(options: .alert) { didAllow, error in
            if didAllow {
                shared.dispatchReminderNotification()
            } else {
                shared.disableNotifications()
            }
        }
    }
    
    func checkForSystemNotificationPermition() {
        notificationCenter.getNotificationSettings { [weak self] notificationSettings in
            switch notificationSettings.authorizationStatus {
            case .authorized, .provisional:
                self?.systemNotificationPermition = true
            case .notDetermined:
                self?.notificationCenter.requestAuthorization(options: .alert) { didAllow, _ in
                    self?.systemNotificationPermition = didAllow
                }
            default:
                self?.systemNotificationPermition = false
            }
        }
    }
    
    func enableNotifications(completionHandler: ((Bool, UNAuthorizationStatus) -> Void)?) {
        notificationCenter.getNotificationSettings { [weak self] notificationSettings in
            switch notificationSettings.authorizationStatus {
            case .authorized, .provisional:
                self?.systemNotificationPermition = true
                self?.isNotificationsAllowedByUser = true
                completionHandler?(true, .authorized)
            case .denied:
                self?.systemNotificationPermition = false
                self?.isNotificationsAllowedByUser = false
                completionHandler?(false, .denied)
            default:
                self?.notificationCenter.requestAuthorization(options: .alert) { didAllow, error in
                    self?.systemNotificationPermition = didAllow
                    self?.isNotificationsAllowedByUser = didAllow
                    completionHandler?(didAllow, .notDetermined)
                }
            }
        }
    }
    
    func disableNotifications() {
        isNotificationsAllowedByUser = false
    }
    
    func dispatchReminderNotification() {
        guard isSystemAllowsNotifications, isNotificationsAllowedByUser else { return }
        
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.title = notificationBody
        content.sound = .defaultRingtone
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderNotificationIdentifier, content: content, trigger: trigger)
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderNotificationIdentifier])
        notificationCenter.add(request)
    }
    
    func setNotificationTitle(_ title: String) {
        notificationTitle = title
        UserDefaults.standard.set(title, forKey: notificationTitleKey)
        dispatchReminderNotification()
    }
    
    func setNotificationBody(_ body: String) {
        notificationBody = body
        UserDefaults.standard.set(body, forKey: notificationBodyKey)
        dispatchReminderNotification()
    }
    
    func setNotificationTime(_ time: Date) {
        notificationTime = time
        UserDefaults.standard.set(time, forKey: notificationTimeKey)
        dispatchReminderNotification()
    }
}
