//
//  TransfersView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 01.10.2024.
//

import SwiftUI

struct TransfersView: View {
    //MARK: - Properties
    @StateObject private var viewModel: TransfersViewModel
    @State private var navigationPath = NavigationPath()
    @State private var selectedAction: ActionWithTransferTransaction?
    @State private var transferToDelete: TransferTransaction?
    @State private var deleteError = false
    private var isIpad: Bool {
        FTAppAssets.currentUserDevise == .pad
    }
    
    //MARK: - Initializer
    init(viewModel: TransfersViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if viewModel.allTransfersAreFetched, !viewModel.isLoading, viewModel.transfers.isEmpty {
                    ContentUnavailableView("No transfers", systemImage: "tray.fill", description: Text("Nothing here yet"))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                
                ForEach(viewModel.transfers) { transfer in
                    TransferRow(transfer: transfer)
                        .onTapGesture {
                            selectedAction = .update(transfer)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                transferToDelete = transfer
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                transferToDelete = transfer
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                
                if !viewModel.allTransfersAreFetched {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onAppear {
                            viewModel.loadData()
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
            .navigationTitle("Transfers")
            .overlay(alignment: .bottom) {
                addButton
            }
            .navigationDestination(item: $selectedAction) { action in
                viewModel.getAddingTransferView(for: action)
            }
            .confirmationDialog(
                "Delete transfer?",
                isPresented:
                        .init(get: { isIpad ? false : transferToDelete != nil }, set: { _ in transferToDelete = nil}),
                titleVisibility: .visible,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let transferToDelete {
                            viewModel.deleteTransfer(transferToDelete) { _ in deleteError = true }
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }, message: {
                    Text("This action is irretable")
                })
            .alert(
                "Delete transfer?",
                isPresented:
                        .init(get: { isIpad ? transferToDelete != nil : false }, set: { _ in transferToDelete = nil}),
                actions: {
                    Button("Delete", role: .destructive) {
                        if let transferToDelete {
                            viewModel.deleteTransfer(transferToDelete) { _ in deleteError = true }
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }, message: {
                    Text("This action is irretable")
                })
            .alert("Deletion failed", isPresented: $deleteError) {
                Button("Ok") {}
            } message: {
                Text("Please, try again")
            }
        }
    }
    
    //MARK: - Computed View properties
    private var addButton: some View {
        Button {
            selectedAction = .add(template: nil)
        } label: {
            Label("Make transfer", systemImage: "plus")
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(.blue)
                }
        }
        .offset(y: -5)
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = TransfersViewModel(dataManager: dataManager)
    
    TransfersView(viewModel: viewModel)
}
