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
    @State private var telegramConfirmationFlag = false
    @State private var emailConfirmationFlag = false
    
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
            
            Text("__Finance Tracker__\nVersion: \(FTAppAssets.appVersion ?? "Yes")")
                .frame(maxWidth: .infinity)
                .foregroundStyle(.tertiary)
                .listRowBackground(Color.clear)
                .multilineTextAlignment(.center)
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
            case .budgets:
                viewModel.getBudgetsView()
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
        Section("Tabs") {
            NavigationLink(value: SettingsSectionAndDataType.budgets) {
                Label("Budget", systemImage: "xmark")
            }
        }
    }
    
    private var appSettingsSection: some View {
        Section("App and Data") {
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
                    }
                    
                    Button("Send mail", action: sendMailToDeveloper)
                }
            
            Link(destination: URL(string: viewModel.codeSource)!) {
                Label("Code source", systemImage: "chevron.left.forwardslash.chevron.right")
            }
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
