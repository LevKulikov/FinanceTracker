//
//  DeveloperToolView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.08.2024.
//

import SwiftUI

struct DeveloperToolView: View {
    //MARK: - Properties
    @StateObject private var viewModel: DeveloperToolViewModel
    
    //MARK: - Initializer
    init(viewModel: DeveloperToolViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Picker("Select balance account", selection: $viewModel.selectedBalanceAccount) {
                    ForEach(viewModel.balanceAccounts) { balanceAccount in
                        Text(balanceAccount.name)
                            .tag(Optional(balanceAccount))
                    }
                }
                
                Picker("Select category", selection: $viewModel.selectedCategory) {
                    ForEach(viewModel.categories) { category in
                        Text(category.name)
                            .tag(Optional(category))
                    }
                }
                
                TextField("Enter number", text: $viewModel.transactionsCountString)
                    .keyboardType(.numberPad)
                
                Section {
                    Button {
                        insert()
                    } label: {
                        Text("Insert")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Developer tool")
        }
    }
    
    //MARK: - Methods
    private func insert() {
        Task {
            await viewModel.insertTransactions()
        }
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = DeveloperToolViewModel(dataManager: dataManager)
    return DeveloperToolView(viewModel: viewModel)
}
