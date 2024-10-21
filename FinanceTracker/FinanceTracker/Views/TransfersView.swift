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
