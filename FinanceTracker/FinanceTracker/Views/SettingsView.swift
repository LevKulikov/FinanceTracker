//
//  SettingsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 19.06.2024.
//

import SwiftUI

struct SettingsView: View {
    enum SettingsSection {
        case categories
        case balanceAccounts
        case tags
        case appearance
        case data
    }
    
    //MARK: - Properties
    @Environment(\.openURL) var openURL
    @StateObject private var viewModel: SettingsViewModel
    @State private var selectedSettings: SettingsSection?
    @State private var telegramConfirmationFlag = false
    @State private var emailConfirmationFlag = false
    private let developerTelegramUsername = "k_lev_s"
    private let developerEmail = "levkulikov.appdev@gmail.com"
    
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
        List(selection: $selectedSettings) {
            enitiesSection
            
            appSettingsSection
            
            contactsSection
            
            Text("App version: idk 🫤")
                .frame(maxWidth: .infinity)
                .foregroundStyle(.tertiary)
                .listRowBackground(Color.clear)
        }
    }
    
    @ViewBuilder
    private var selectedSettingsView: some View {
        if let selectedSettings {
            switch selectedSettings {
            case .categories:
                inDevelopmentPlaceholder
            case .balanceAccounts:
                inDevelopmentPlaceholder
            case .tags:
                inDevelopmentPlaceholder
            case .appearance:
                inDevelopmentPlaceholder
            case .data:
                inDevelopmentPlaceholder
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
            NavigationLink(value: SettingsSection.balanceAccounts) {
                Label("Balance Accounts", systemImage: "person.crop.circle")
            }
            
            NavigationLink(value: SettingsSection.categories) {
                Label("Categories", systemImage: "star.square.on.square")
            }
            
            NavigationLink(value: SettingsSection.tags) {
                Label("Tags", systemImage: "number")
            }
        }
    }
    
    private var appSettingsSection: some View {
        Section("App and Data") {
            NavigationLink(value: SettingsSection.appearance) {
                Label("Appearance", systemImage: "circle.righthalf.filled")
            }
            
            NavigationLink(value: SettingsSection.data) {
                Label("Stored data", systemImage: "cylinder.split.1x2")
            }
        }
    }
    
    private var contactsSection: some View {
        Section("Developer's contacts") {
            Label("Telegram", systemImage: "paperplane")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    telegramConfirmationFlag.toggle()
                }
                .confirmationDialog("@" + developerTelegramUsername, isPresented: $telegramConfirmationFlag, titleVisibility: .visible) {
                    Button("Copy username") {
                        copyAsPlainText("@" + developerTelegramUsername)
                    }
                    
                    Link("Send message", destination: URL(string: "https://t.me/" + developerTelegramUsername)!)
                }
            
            Label("Email", systemImage: "envelope")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    emailConfirmationFlag.toggle()
                }
                .confirmationDialog(developerEmail, isPresented: $emailConfirmationFlag, titleVisibility: .visible) {
                    Button("Copy email") {
                        copyAsPlainText(developerEmail)
                    }
                    
                    Button("Send mail", action: sendMailToDeveloper)
                }
        }
    }
    
    //MARK: - Methods
    private func sendMailToDeveloper() {
        let mail = "mailto:" + developerEmail
        guard let mailURL = URL(string: mail) else { return }
        openURL(mailURL)
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = SettingsViewModel(dataManager: dataManger)
    
    return SettingsView(viewModel: viewModel)
}
