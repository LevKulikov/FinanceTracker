//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 19.06.2024.
//

import SwiftUI

struct SettingsView: View {
    //MARK: - Properties
    @Environment(\.openURL) var openURL
    @StateObject private var viewModel: SettingsViewModel
    @State private var showTabsSettingsView = false
    @State private var telegramConfirmationFlag = false
    @State private var emailConfirmationFlag = false
    
    @State private var showDeveloperTool = false
    
    //MARK: - Initializer
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationSplitView {
            settingsList
                .navigationTitle("Settings")
        } detail: {
            selectedSettingsView
        }
    }
    
    //MARK: - Computed View Prop
    private var settingsList: some View {
        List(selection: $viewModel.selectedSettings) {
            enitiesSection
            
            tabsSection
            
            appSettingsSection
            
            contactsSection
            
            bottomAppVersionView
            
            Rectangle()
                .fill(.clear)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .sheet(isPresented: $showTabsSettingsView) {
            viewModel.getTabsSettingsView()
        }
        .sheet(isPresented: $showDeveloperTool) {
            viewModel.getDeveloperToolView()
        }
    }
    
    @ViewBuilder
    private var selectedSettingsView: some View {
        if let selectedSettings = viewModel.selectedSettings {
            switch selectedSettings {
            case .categories:
                viewModel.getCategoriesView()
            case .balanceAccounts:
                viewModel.getBalanceAccountsView()
            case .tags:
                viewModel.getTagsView()
            case .appearance:
                viewModel.getAppearanceView()
            case .data:
                viewModel.getManageDataView()
            case .transactions:
                EmptyView()
            case .budgets: // .budgets is used to identify additional tab to show
                viewModel.getAdditionalTabView()
            case .notifications:
                viewModel.getNotificationsView()
            }
        } else {
            noSelectionView
        }
    }
    
    private var noSelectionView: some View {
        VStack {
            Text("Setting is not selected")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Please select any setting in the left-hand menu")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var inDevelopmentPlaceholder: some View {
        Label("In development", systemImage: "chevron.left.forwardslash.chevron.right")
            .font(.title)
            .foregroundStyle(.secondary)
    }
    
    private var enitiesSection: some View {
        Section("Entities") {
            NavigationLink(value: SettingsSectionAndDataType.balanceAccounts) {
                Label("Balance Accounts", systemImage: "person.crop.circle")
            }
            
            NavigationLink(value: SettingsSectionAndDataType.categories) {
                Label("Categories", systemImage: "star.square.on.square")
            }
            
            NavigationLink(value: SettingsSectionAndDataType.tags) {
                Label("Tags", systemImage: "number")
            }
        }
    }
    
    private var tabsSection: some View {
        Section("Additional tabs") {
            if let additionalTab = viewModel.additionalTab {
                NavigationLink(value: SettingsSectionAndDataType.budgets) {
                    additionalTab.label
                }
            }
            
            Button("Reorder tabs", systemImage: "ellipsis.rectangle") {
                showTabsSettingsView = true
            }
        }
    }
    
    private var appSettingsSection: some View {
        Section("App and Data") {
            NavigationLink(value: SettingsSectionAndDataType.notifications) {
                Label("Notifications", systemImage: "bell.badge")
            }
            
            NavigationLink(value: SettingsSectionAndDataType.appearance) {
                Label("Appearance", systemImage: "circle.righthalf.filled")
            }
            
            NavigationLink(value: SettingsSectionAndDataType.data) {
                Label("Stored data", systemImage: "cylinder.split.1x2")
            }
        }
    }
    
    private var contactsSection: some View {
        Section("Developer") {
            Label("Telegram", systemImage: "paperplane")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    telegramConfirmationFlag.toggle()
                }
                .confirmationDialog("@" + viewModel.developerTelegramUsername, isPresented: $telegramConfirmationFlag, titleVisibility: .visible) {
                    Button("Copy username") {
                        copyAsPlainText("@" + viewModel.developerTelegramUsername)
                        Toast.shared.present(
                            title: String(localized: "Username is copied"),
                            symbol: "doc.on.doc",
                            tint: .blue
                        )
                    }
                    
                    Link("Send message", destination: URL(string: "https://t.me/" + viewModel.developerTelegramUsername)!)
                }
            
            Label("Email", systemImage: "envelope")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    emailConfirmationFlag.toggle()
                }
                .confirmationDialog(viewModel.developerEmail, isPresented: $emailConfirmationFlag, titleVisibility: .visible) {
                    Button("Copy email") {
                        copyAsPlainText(viewModel.developerEmail)
                        Toast.shared.present(
                            title: String(localized: "Email is copied"),
                            symbol: "doc.on.doc",
                            tint: .blue
                        )
                    }
                    
                    Button("Send mail", action: sendMailToDeveloper)
                }
            
            Link(destination: URL(string: viewModel.codeSource)!) {
                Label("Code source", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }
    
    private var bottomAppVersionView: some View {
        Text("__Finance Tracker__\nVersion: \(FTAppAssets.appVersion ?? "Yes")")
            .frame(maxWidth: .infinity)
            .foregroundStyle(.tertiary)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .multilineTextAlignment(.center)
            .onTapGesture(count: 3) {
                Toast.shared.present(
                    title: String(localized: "Show?"),
                    subtitle: String(localized: "Developer tool"),
                    symbol: "chevron.left.forwardslash.chevron.right",
                    action: .init(symbol: "lock.open", hideAfterAction: true, action: {
                        showDeveloperTool.toggle()
                    })
                )
            }
    }
    
    //MARK: - Methods
    private func sendMailToDeveloper() {
        let mail = "mailto:" + viewModel.developerEmail
        guard let mailURL = URL(string: mail) else { return }
        openURL(mailURL)
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = SettingsViewModel(dataManager: dataManger)
    
    return SettingsView(viewModel: viewModel)
}
