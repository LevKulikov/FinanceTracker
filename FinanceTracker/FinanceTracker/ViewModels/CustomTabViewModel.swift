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
    
    func didUpdateFromSettings(for section: SettingsSection)
}

final class CustomTabViewModel: ObservableObject {
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
    @Published var showTabBar = true
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func addButtonPressed() {
        delegates.forEach { $0.object?.addButtonPressed() }
    }
    
    func getSpendIncomeView(namespace: Namespace.ID) -> some View {
        let viewModel = SpendIncomeViewModel(dataManager: dataManager)
        viewModel.delegate = self
        addDelegate(object: viewModel)
        return SpendIncomeView(viewModel: viewModel, namespace: namespace)
    }
    
    func getStatisticsView() -> some View {
        return FTFactory.shared.createStatisticsView(dataManager: dataManager)
    }
    
    // This method does not use FTFactory as viewModel need to be set as delegate, using FTFactory avoids this action
    func getSearchView() -> some View {
        let viewModel = SearchViewModel(dataManager: dataManager)
        viewModel.delegate = self
        addDelegate(object: viewModel)
        return SearchView(viewModel: viewModel)
    }
    
    func getSettingsView() -> some View {
        return FTFactory.shared.createSettingsView(dataManager: dataManager, delegate: self)
    }
    
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
            $0.object?.didUpdateFromSettings(for: .data)
            print($0.object?.id)
        }
    }
}

//MARK: Extension for SettingsViewModelDelegate
extension CustomTabViewModel: SettingsViewModelDelegate {
    func didSelectSetting(_ setting: SettingsSection?) {
        DispatchQueue.main.async { [weak self] in
            if setting == nil {
                withAnimation {
                    self?.showTabBar = true
                }
            } else {
                withAnimation {
                    self?.showTabBar = false
                }
            }
        }
    }
    
    func didUpdateSettingsSection(_ section: SettingsSection) {
        delegates.forEach { $0.object?.didUpdateFromSettings(for: section) }
    }
}

//MARK: Extension for SearchViewModelDelegate
extension CustomTabViewModel: SearchViewModelDelegate {
    func didUpdatedTransactionsList() {
        delegates.forEach {
            $0.object?.didUpdateFromSettings(for: .data)
            print($0.object?.id)
        }
    }
    
    func hideTabBar(_ hide: Bool) {
        withAnimation {
            showTabBar = !hide
        }
    }
}
