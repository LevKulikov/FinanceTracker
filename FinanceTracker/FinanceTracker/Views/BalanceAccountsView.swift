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
                "Delete balance account?",
                isPresented: .init(get: { deleteBalanceAccountFlag != nil }, set: { _ in deleteBalanceAccountFlag = nil }),
                titleVisibility: .visible) {
                    //TODO: Implement balance account deletion
                    Button("Ok", action: {})
                } message: {
                    Text("This feature has not been implemented yet, balance account \"\(deleteBalanceAccountFlag?.name ?? "")\" cannot be deleted")
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
            
            FTAppAssets.iconImageOrEpty(name: balanceAccount.iconName)
                .frame(width: 30, height: 30)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                deleteBalanceAccountFlag = balanceAccount
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = BalanceAccountsViewModel(dataManager: dataManger)
    
    return BalanceAccountsView(viewModel: viewModel)
}
