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
    case addingSpendIncomeView
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
    
    @ViewBuilder
    var label: some View {
        Label(LocalizedStringKey(tabTitle.key), systemImage: imageSystemName)
    }
    
    var tabImage: Image {
        return Image(systemName: imageSystemName)
    }
    
    var imageSystemName: String {
        switch self {
        case .spendIncomeView:
            return "list.bullet.clipboard"
        case .addingSpendIncomeView:
            return "plus"
        case .searchView:
            return "magnifyingglass"
        case .statisticsView:
            return "chart.bar"
        case .settingsView:
            return "gear"
        case .welcomeView:
            return "star"
        case .budgetsView:
            return "dollarsign.square"
        }
    }
    
    var tabTitle: LocalizedStringResource {
        switch self {
        case .spendIncomeView:
            return "List"
        case .addingSpendIncomeView:
            return "Add"
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
    
    static var changableTabs: [Self] { [.spendIncomeView, .statisticsView, .searchView, .settingsView, .budgetsView] }
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
    private var defaultBalanceAccount: BalanceAccount?
    
    //MARK: Published props
    @Published var tabSelection = 1
    @Published var showTabBar = true
    @Published var isFirstLaunch = false
    @MainActor @Published private(set) var firstThreeTabs: [TabViewType]
    @MainActor @Published private(set) var showAddButtonFromEvetyTab: Bool
    
    @ViewBuilder
    var page404: some View {
        VStack {
            Text("404")
                .bold()
                .monospaced()
                .font(.largeTitle)
            
            Text("Sorry, some error occured. This page doesn't exist")
                .multilineTextAlignment(.center)
        }
    }
    
    @MainActor
    var isFirstTabCanBeShown: Bool {
        guard firstThreeTabs.count > 0 else { return false }
        return true
    }
    
    @MainActor
    var isSecondTabCanBeShown: Bool {
        guard firstThreeTabs.count > 1 else { return false }
        return true
    }
    
    @MainActor
    var isThirdTabCanBeShown: Bool {
        guard firstThreeTabs.count > 2 else { return false }
        return true
    }
    
    @MainActor
    var isForthTabCanBeShown: Bool {
        guard firstThreeTabs.count > 3 else { return false }
        return true
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        self.isFirstLaunch = dataManager.isFirstLaunch
        self._firstThreeTabs = Published(wrappedValue: dataManager.getSecondThirdTabsArray())
        self._showAddButtonFromEvetyTab = Published(wrappedValue: dataManager.showAddButtonFromEvetyTab())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.defaultBalanceAccount = dataManager.getDefaultBalanceAccount()
        }
    }
    
    //MARK: - Methods
    func addButtonPressed() {
        delegates.forEach { $0.object?.addButtonPressed() }
    }
    
    @MainActor
    func getSpendIncomeView(namespace: Namespace.ID) -> some View {
        return FTFactory.shared.createSpendIncomeView(dataManager: dataManager, delegate: self, namespace: namespace, strongReference: true) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    @MainActor
    func getStatisticsView() -> some View {
        return FTFactory.shared.createStatisticsView(dataManager: dataManager, delegate: self, strongReference: true) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    @MainActor
    func getSearchView() -> some View {
        return FTFactory.shared.createSearchView(dataManager: dataManager, delegate: self, strongReference: true) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    @MainActor
    func getBudgetsView() -> some View {
        return FTFactory.shared.createBudgetsView(dataManager: dataManager, delegate: self, strongReference: true) { [weak self] viewModel in
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
    
    @MainActor
    func getFirstTab(namespace: Namespace.ID) -> AnyView {
        getTab(index: 0, namespace: namespace)
    }
    
    @MainActor
    func getSecondTab(namespace: Namespace.ID) -> AnyView {
        getTab(index: 1, namespace: namespace)
    }
    
    @MainActor
    func getThirdTab(namespace: Namespace.ID) -> AnyView {
        getTab(index: 2, namespace: namespace)
    }
    
    @MainActor
    func getForthTab(namespace: Namespace.ID) -> AnyView {
        getTab(index: 3, namespace: namespace)
    }
    
    @MainActor
    func getAddingSpendIncomeView(forAction: Binding<ActionWithTransaction>, namespace: Namespace.ID) -> some View {
        return FTFactory.shared.createAddingSpendIcomeView(
            dataManager: dataManager,
            threadToUse: .main,
            transactionType: .spending,
            balanceAccount: defaultBalanceAccount  ?? .emptyBalanceAccount,
            forAction: forAction,
            namespace: namespace,
            delegate: self
        )
    }
    
    //MARK: Private methods
    private func addDelegate(object: some CustomTabViewModelDelegate) {
        guard !delegates.contains(where: { $0.object?.id == object.id }) else { return }
        delegates.append(WeakReferenceDelegate(object))
        delegates = delegates.filter { $0.object != nil }
    }
    
    @MainActor
    private func getTab(index: Int, namespace: Namespace.ID) -> AnyView {
        guard firstThreeTabs.count > index else { return AnyView(page404) }
        switch firstThreeTabs[index] {
        case .spendIncomeView:
            return AnyView(getSpendIncomeView(namespace: namespace))
        case .addingSpendIncomeView:
            return AnyView(page404)
        case .searchView:
            return AnyView(getSearchView())
        case .statisticsView:
            return AnyView(getStatisticsView())
        case .settingsView:
            return AnyView(getSettingsView())
        case .welcomeView:
            return AnyView(page404)
        case .budgetsView:
            return AnyView(getBudgetsView())
        }
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
    func didSetSecondThirdTabsPosition(for tabsPositions: [TabViewType]) {
        Task { @MainActor in
            firstThreeTabs = tabsPositions
        }
    }
    
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
        switch section {
        case .balanceAccounts:
            defaultBalanceAccount = dataManager.getDefaultBalanceAccount()
        case .appearance:
            Task { @MainActor in
                showAddButtonFromEvetyTab = dataManager.showAddButtonFromEvetyTab()
            }
        default:
            break
        }
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

//MARK: Extension for BudgetsViewModelDelegate
extension CustomTabViewModel: BudgetsViewModelDelegate {
    func didAddBudget(_ budget: Budget) {
        return
    }
    
    func didUpdateBudget(_ budget: Budget) {
        return
    }
    
    func didDeleteBudget(_ budget: Budget) {
        return
    }
    
    func didUpdateTransaction() {
        delegates.forEach {
            $0.object?.didUpdateData(for: .transactions, from: .budgetsView)
        }
    }
}

//MARK: Extension for AddingSpendIcomeViewModelDelegate
extension CustomTabViewModel: AddingSpendIcomeViewModelDelegate {
    func addedNewTransaction(_ transaction: Transaction) {
        delegates.forEach {
            $0.object?.didUpdateData(for: .transactions, from: .addingSpendIncomeView)
        }
    }
    
    func updateTransaction(_ transaction: Transaction) {
        delegates.forEach {
            $0.object?.didUpdateData(for: .transactions, from: .addingSpendIncomeView)
        }
    }
    
    func deletedTransaction(_ transaction: Transaction) {
        delegates.forEach {
            $0.object?.didUpdateData(for: .transactions, from: .addingSpendIncomeView)
        }
    }
    
    func transactionsTypeReselected(to newType: TransactionsType) {
        return
    }
    
    func categoryUpdated() {
        delegates.forEach {
            $0.object?.didUpdateData(for: .data, from: .addingSpendIncomeView)
        }
    }
}
