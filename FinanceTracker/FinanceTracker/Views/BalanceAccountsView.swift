//
//  BalanceAccountsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.06.2024.
//

import SwiftUI

struct BalanceAccountsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: BalanceAccountsViewModel
    @State private var deleteBalanceAccountFlag: BalanceAccount?
    @State private var navigationPath = NavigationPath()
    private var canDeleteBalanceAccount: Bool {
        guard let defaultBalanceAccount = viewModel.defaultBalanceAccount else { return false }
        return defaultBalanceAccount != deleteBalanceAccountFlag
    }
    
    //MARK: - Initializer
    init(viewModel: BalanceAccountsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(viewModel.balanceAccounts) { balanceAccount in
                    getBalanceAccountRow(for: balanceAccount)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Balance Accounts")
            .navigationDestination(for: ActionWithBalanceAccaunt.self) { action in
                viewModel.getAddingBalanceAccountView(for: action)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        navigationPath.append(ActionWithBalanceAccaunt.add)
                    }
                }
            }
            .confirmationDialog(
                canDeleteBalanceAccount ? "Delete balance account?" : "Unable to delete",
                isPresented: .init(get: { deleteBalanceAccountFlag != nil }, set: { _ in deleteBalanceAccountFlag = nil }),
                titleVisibility: .visible) {
                    getActionsForDeleteDialog(balanceAccount: deleteBalanceAccountFlag)
                } message: {
                    getMessageForDeleteDialog(balanceAccount: deleteBalanceAccountFlag)
                }
        }
    }
    
    //MARK: - Computed View Properties
    
    //MARK: - Methods
    @ViewBuilder
    private func getBalanceAccountRow(for balanceAccount: BalanceAccount) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(balanceAccount.name)
                    .bold()
                
                Text(balanceAccount.currency)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading)
            
            Spacer()
            
            HStack {
                if balanceAccount == viewModel.defaultBalanceAccount {
                    Text("default")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .stroke(.secondary)
                        }
                }
                
                FTAppAssets.iconImageOrEpty(name: balanceAccount.iconName)
                    .frame(width: 30, height: 30)
            }
            .padding(.trailing)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding(.vertical)
        .background {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [.init(color: .clear, location: 0.2), .init(color: balanceAccount.color, location: 1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            navigationPath.append(ActionWithBalanceAccaunt.update(balanceAccount))
        }
        .contextMenu {
            Button("Set as default", systemImage: "checkmark") {
                viewModel.setDefaultBalanceAccount(balanceAccount)
            }
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteBalanceAccountFlag = balanceAccount
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                deleteBalanceAccountFlag = balanceAccount
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
    
    @ViewBuilder
    private func getActionsForDeleteDialog(balanceAccount: BalanceAccount?) -> some View {
        if let defaultBalanceAccount = viewModel.defaultBalanceAccount, let balanceAccount {
            if defaultBalanceAccount != balanceAccount {
                Button("Delete only balance account", role: .destructive) {
                    viewModel.deleteBalanceAccount(balanceAccount)
                }
                Button("Delete with transactions", role: .destructive) {
                    viewModel.deleteBalanceAccountWithTransactions(balanceAccount)
                }
            } else {
                Button("Ok", action: {})
            }
        } else {
            Button("Ok", action: {})
        }
    }
    
    @ViewBuilder
    private func getMessageForDeleteDialog(balanceAccount: BalanceAccount?) -> some View {
        if let defaultBalanceAccount = viewModel.defaultBalanceAccount {
            if defaultBalanceAccount != balanceAccount {
                Text("This action is irretable. There are two ways to delete:\n\n - Delete only balance account: all transactions binded to deleted balance account will be moved to default one\n\n - Delete with transactions: balance account and binded to this account transactions will be deleted")
            } else {
                Text("Unable to delete default balance account. Set an another balance account as default if you need to delete the selected one")
            }
        } else {
            Text("Set the default balance account first")
        }
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = BalanceAccountsViewModel(dataManager: dataManger)
    
    return BalanceAccountsView(viewModel: viewModel)
}
