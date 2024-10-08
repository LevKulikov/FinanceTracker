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
    
    //MARK: - Initializer
    init(viewModel: TransfersViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                if viewModel.allTransfersAreFetched, !viewModel.isLoading, viewModel.transfers.isEmpty {
                    ContentUnavailableView("No transfers", systemImage: "tray.fill", description: Text("Nothing here yet"))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                
                ForEach(viewModel.transfers) { transfer in
                    Text(transfer.date.formatted(.dateTime))
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
            }
            .navigationTitle("Transfers")
        }
    }
    
    //MARK: - Computed View properties
    
    //MARK: - Methods
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = TransfersViewModel(dataManager: dataManager)
    
    TransfersView(viewModel: viewModel)
}
