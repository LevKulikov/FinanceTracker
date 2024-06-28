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
        return FTFactory.createStatisticsView(dataManager: dataManager)
    }
    
    func getSearchView() -> some View {
        return FTFactory.createSearchView(dataManager: dataManager, delegate: self) { [weak self] viewModel in
            self?.addDelegate(object: viewModel)
        }
    }
    
    func getSettingsView() -> some View {
        return FTFactory.createSettingsView(dataManager: dataManager, delegate: self)
    }
    
    private func addDelegate(object: some CustomTabViewModelDelegate) {
        guard !delegates.contains(where: { $0.object?.id == object.id }) else { return }
        delegates.append(WeakReferenceDelegate(object))
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
        delegates.forEach { $0.object?.didUpdateFromSettings(for: .data) }
    }
}
