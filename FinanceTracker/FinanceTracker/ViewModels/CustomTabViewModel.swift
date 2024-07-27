//
//  CustomTabViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 11.06.2024.
//

import Foundation
import SwiftUI

protocol CustomTabViewModelDelegate: AnyObject {
    /// ID to prevents doublicates
    var id: String { get }
    
    func addButtonPressed()
    
    func didUpdateData(for dataType: SettingsSectionAndDataType, from tabView: TabViewType)
}

enum TabViewType: String, Equatable, Hashable, Identifiable {
    case spendIncomeView
    case searchView
    case statisticsView
    case settingsView
    case welcomeView
    case budgetsView
    
    var id: Self { return self }
    
    @ViewBuilder
    var tabLabel: some View {
        VStack {
            tabImage
                .frame(height: imageHeight)
            
            Text(tabTitle)
                .font(.caption)
        }
    }
    
    var tabImage: Image {
        switch self {
        case .spendIncomeView:
            return Image(systemName: "list.bullet.clipboard")
        case .searchView:
            return Image(systemName: "magnifyingglass")
        case .statisticsView:
            return Image(systemName: "chart.bar")
        case .settingsView:
            return Image(systemName: "gear")
        case .welcomeView:
            return Image(systemName: "star")
        case .budgetsView:
            return Image(systemName: "dollarsign.square")
        }
    }
    
    var tabTitle: LocalizedStringResource {
        switch self {
        case .spendIncomeView:
            return "List"
        case .searchView:
            return "Search"
        case .statisticsView:
            return "Charts"
        case .settingsView:
            return "Settings"
        case .welcomeView:
            return "Welcome"
        case .budgetsView:
            return "Budgets"
        }
    }
    
    var imageHeight: CGFloat { 20 }
    
    var changableTabs: [Self] { [.statisticsView, .searchView, .budgetsView] }
}

final class CustomTabViewModel: ObservableObject, @unchecked Sendable {
    private struct WeakReferenceDelegate {
        weak var object: (any CustomTabViewModelDelegate)?
        
        init(_ object: some CustomTabViewModelDelegate) {
            self.object = object
        }
    }
    
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    private var delegates: [WeakReferenceDelegate] = []
    
    //MARK: Published props
    @Published var tabSelection = 1
    @Published var showTabBar = true
    @Published var isFirstLaunch = false
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        self.isFirstLaunch = dataManager.isFirstLaunch
    }
    
    //MARK: - Methods
    func addButtonPressed() {
        delegates.forEach { $0.object?.addButtonPressed() }
    }
    
    @MainActor
    func getSpendIncomeView(namespace: Namespace.ID) -> some View {
        return FTFactory.shared.createSpendIncomeView(dataManager: dataManager, delegate: self, namespace: namespace) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    @MainActor
    func getStatisticsView() -> some View {
        return FTFactory.shared.createStatisticsView(dataManager: dataManager, delegate: self) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    @MainActor
    func getSearchView() -> some View {
        return FTFactory.shared.createSearchView(dataManager: dataManager, delegate: self) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    @MainActor
    func getSettingsView() -> some View {
        return FTFactory.shared.createSettingsView(dataManager: dataManager, delegate: self)
    }
    
    @MainActor
    func getWelcomeView() -> some View {
        return FTFactory.shared.createWelcomeView(dataManager: dataManager, delegate: self)
    }
    
//    @MainActor
//    func getSecondTab() -> some View {
//        
//    }
    
//    @MainActor
//    func getThirdTab() -> some View {
//        
//    }
    
    //MARK: Private methods
    private func addDelegate(object: some CustomTabViewModelDelegate) {
        guard !delegates.contains(where: { $0.object?.id == object.id }) else { return }
        delegates.append(WeakReferenceDelegate(object))
        delegates = delegates.filter { $0.object != nil }
    }
}

//MARK: - Extensions
//MARK: Extension for SpendIncomeViewModelDelegate
extension CustomTabViewModel: SpendIncomeViewModelDelegate {
    func didSelectAction(_ action: ActionWithTransaction) {
        switch action {
        case .none:
            withAnimation {
                showTabBar = true
            }
        case .add, .update:
            withAnimation {
                showTabBar = false
            }
        }
    }
    
    func didUpdateTransactionList() {
        delegates.forEach {
            $0.object?.didUpdateData(for: .data, from: .spendIncomeView)
        }
    }
}

//MARK: Extension for StatisticsViewModelDelegate
extension CustomTabViewModel: StatisticsViewModelDelegate {
    func showTabBar(_ show: Bool) {
        withAnimation {
            showTabBar = show
        }
    }
    
    func didUpdatedTransactionsListFromStatistics() {
        delegates.forEach {
            $0.object?.didUpdateData(for: .transactions, from: .statisticsView)
        }
    }
}

//MARK: Extension for SettingsViewModelDelegate
extension CustomTabViewModel: SettingsViewModelDelegate {
    func didSelectSetting(_ setting: SettingsSectionAndDataType?) {
        Task { @MainActor in
            if setting == nil {
                withAnimation {
                    showTabBar = true
                }
            } else {
                withAnimation {
                    showTabBar = false
                }
            }
        }
    }
    
    func didUpdateSettingsSection(_ section: SettingsSectionAndDataType) {
        delegates.forEach { $0.object?.didUpdateData(for: section, from: .settingsView) }
    }
}

//MARK: Extension for SearchViewModelDelegate
extension CustomTabViewModel: SearchViewModelDelegate {
    func didUpdatedTransactionsList() {
        delegates.forEach {
            $0.object?.didUpdateData(for: .data, from: .searchView)
        }
    }
    
    func hideTabBar(_ hide: Bool) {
        withAnimation {
            showTabBar = !hide
        }
    }
}

//MARK: Extension for WelcomeViewModelDelegate
extension CustomTabViewModel: WelcomeViewModelDelegate {
    func didCreateBalanceAccount() {
        delegates.forEach {
            $0.object?.didUpdateData(for: .balanceAccounts, from: .welcomeView)
        }
    }
}
