//
//  TransactionListView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 16.07.2024.
//

import SwiftUI

struct TransactionListView: View {
    //MARK: - Properties
    @StateObject private var viewModel: TransactionListViewModel
    @State private var showTransaction: Transaction?
    @State private var transactionToDelete: Transaction?
    @Namespace private var namespace
    
    //MARK: - Initializer
    init(viewModel: TransactionListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                if viewModel.filteredTransactionGroups.isEmpty {
                    ContentUnavailableView("No transactions", systemImage: "tray.fill", description: Text("Nothing here yet"))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                
                ForEach(viewModel.filteredTransactionGroups) { transGroup in
                    SearchSection(transactionGroupData: transGroup) { transaction in
                        showTransaction = transaction
                    } onDeleteSwipe: { transaction in
                        transactionToDelete = transaction
                    }
                }
                
                Section {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 40)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                }
            }
            .navigationTitle(viewModel.title)
            .overlay {
                if viewModel.isGroupingAndSortingProceeds {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .confirmationDialog(
                "Delete transaction?",
                isPresented: .init(get: { transactionToDelete != nil }, set: { _ in transactionToDelete = nil}),
                titleVisibility: .visible,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let transactionToDelete {
                            viewModel.deleteTransaction(transactionToDelete)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }, message: {
                    Text("This action is irretable")
                })
            .fullScreenCover(item: $showTransaction) { transaction in
                viewModel.getAddingSpendIcomeView(for: transaction, namespace: namespace)
            }
        }
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = TransactionListViewModel(dataManager: dataManger, transactions: [], title: "Some", threadToUse: .global)
    return TransactionListView(viewModel: viewModel)
}
