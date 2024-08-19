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
                Text("This window is used to test the App performance during high loading. It creates bench of transactions (default it is 5000) for a selected Balance Account and Category. All transactions are created for the current date, so __do not push the button \"Insert\"__ if you don't want to dramatically slow down the App")
                    .foregroundStyle(.secondary)
                
                Section {
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
                    
                    HStack {
                        Text("Enter number")
                        
                        TextField("Enter number", text: $viewModel.transactionsCountString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("Value of each transaction will be equal to the number entered")
                }
                
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
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .overlay {
                if viewModel.isProcessing {
                    ProgressView()
                        .controlSize(.large)
                }
            }
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
