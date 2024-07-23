//
//  NotificationsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 22.07.2024.
//

import SwiftUI

struct NotificationsView: View {
    //MARK: - Properties
    @Environment(\.openURL) var openURL
    @StateObject private var viewModel: NotificationsViewModel
    @FocusState private var titleFocus
    @FocusState private var bodyFocus
    @FocusState private var timeFocus
    
    //MARK: - Initializer
    init(viewModel: NotificationsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                turnNotificationSection
                
                notificationDetailsSection
            }
            .navigationTitle("Notifications")
            .toolbar {
                if bodyFocus {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        
                        Button("Done") {
                            bodyFocus = false
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Computed View Properties
    private var turnNotificationSection: some View {
        Section {
            Toggle("Daily reminder", isOn: $viewModel.notificationsIsEnabled)
                .disabled(!viewModel.isSystemAllowsNotifications)
            
            if !viewModel.isSystemAllowsNotifications {
                VStack {
                    Text("You have prevented the application from sending notifications. \(Text("Click here").foregroundStyle(.blue)) to go to Settings and allow notifications to be sent.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            if let notificationsURL = UIApplication.appNotificationSettingsURL {
                                openURL(notificationsURL)
                            }
                        }
                }
            }
        }
    }
    
    private var notificationDetailsSection: some View {
        Section("Time, Title and Body") {
            DatePicker("Reminder time", selection: $viewModel.notificationTime, displayedComponents: .hourAndMinute)
            
            TextField("Reminder title", text: $viewModel.notificationTitle)
                .focused($titleFocus)
                .submitLabel(.done)
                .onChange(of: titleFocus) {
                    if !titleFocus {
                        viewModel.saveNotificationTitle()
                    }
                }
            
            TextField("Reminder body", text: $viewModel.notificationBody, axis: .vertical)
                .lineLimit(1...3)
                .focused($bodyFocus)
                .onChange(of: bodyFocus) {
                    if !bodyFocus {
                        viewModel.saveNotificationBody()
                    }
                }
        }
    }
    
    //MARK: - Methods
    
}

#Preview {
    let notificationManager = NotificationManager()
    let viewModel = NotificationsViewModel(notificationManager: notificationManager)
    
    return NotificationsView(viewModel: viewModel)
}
