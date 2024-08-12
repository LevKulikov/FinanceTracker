//
//  ManageDataView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.06.2024.
//

import SwiftUI

struct ManageDataView: View {
    //MARK: - Properties
    @StateObject private var viewModel: ManageDataViewModel
    
    @State private var deleteTransactionsFirstAlert = false
    @State private var deleteTransactionsSecondAlert = false
    
    @State private var deleteAllDataFirstAlert = false
    @State private var deleteAllDataSecondAlert = false
    
    //MARK: - Initializer
    init(viewModel: ManageDataViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                csvSection
                
                Section {
                    exportButton
                }
                
                Section {
                    deleteAllTransactionsRow
                }
                
                Section {
                    deleteAllStoredDataRow
                }
            }
            .navigationTitle("Data settings")
            .confirmationDialog("Delete all transactions?", isPresented: $deleteTransactionsFirstAlert, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteTransactionsSecondAlert.toggle()
                }
            } message: {
                Text("Are you sure? All transactions will be deleted, this action is irretable")
            }
            .alert("Final alert!", isPresented: $deleteTransactionsSecondAlert) {
                Button("Yes, delete", role: .destructive) {
                    viewModel.deleteAllTransactions()
                }
                
                Button("No, cancel", role: .cancel, action: {})
            } message: {
                Text("Again, this action is irretable. Do you want to delete all transactions?")
            }
            .confirmationDialog("Delete all data?", isPresented: $deleteAllDataFirstAlert, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteAllDataSecondAlert.toggle()
                }
            } message: {
                Text("Are you sure? All stored data (transactions, balance accounts, categories etc.) will be deleted, this action is irretable \n\nYour can delete only transactions if you would like")
            }
            .alert("Final alert!", isPresented: $deleteAllDataSecondAlert) {
                Button("Yes, delete anyway", role: .destructive) {
                    viewModel.deleteAllStoredData()
                }
                
                Button("No, cancel", role: .cancel, action: {})
            } message: {
                Text("Again, this action is irretable. If you are concerned about privacy, your data is stored only on your device. Do you want to delete all stored data?")
            }
            .sheet(item: $viewModel.fileToExport, content: { item in
                ActivityView(activityItems: [item])
                    .ignoresSafeArea(edges: .bottom)
            })
            .alert("JSON creation error", isPresented: .init(get: { viewModel.dataExportError != nil }, set: {_ in viewModel.dataExportError = nil })) {
                Button("Ok") { }
            } message: {
                Text("An error occurred while creating a JSON file. Error text: \(viewModel.dataExportError?.localizedDescription ?? "no text")")
            }
            .alert("Excel (csv) file creation error", isPresented: .init(get: { viewModel.csvExportError != nil }, set: {_ in viewModel.csvExportError = nil })) {
                Button("Ok") { }
            } message: {
                Text("An error occurred during creating a Excel (csv) file. Error text: \(viewModel.csvExportError?.localizedDescription ?? "no text")")
            }
        }
    }
    
    //MARK: - Computed view props
    private var deleteAllTransactionsRow: some View {
        Button {
            deleteTransactionsFirstAlert.toggle()
        } label: {
            Label("Delete all transactions", systemImage: "trash")
                .foregroundStyle(.red)
        }
        .listRowBackground(Color.red.opacity(0.1))
    }
    
    private var deleteAllStoredDataRow: some View {
        Button {
            deleteAllDataFirstAlert.toggle()
        } label: {
            Label("Delete all stored data", systemImage: "trash")
                .foregroundStyle(.red)
        }
        .listRowBackground(Color.red.opacity(0.1))
    }
    
    private var exportButton: some View {
        HStack {
            Button("Export all data as JSON file", systemImage: "square.and.arrow.up") {
                viewModel.getDataToExport()
            }
            
            Spacer()
            
            if viewModel.isDataFetchingForExport {
                ProgressView()
            }
        }
    }
    
    private var csvSection: some View {
        Section {
            HStack {
                Button("Export transactions as Excel file (csv) for date range", systemImage: "tablecells.badge.ellipsis") {
                    viewModel.getCSVToExport()
                }
                
                if viewModel.isDataFetchingForCSVExport {
                    ProgressView()
                }
            }
            
            DateRangePicker(startDate: $viewModel.csvStartDate, endDate: $viewModel.csvEndDate, dateRange: FTAppAssets.availableDateRange)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = ManageDataViewModel(dataManager: dataManger)
    
    return ManageDataView(viewModel: viewModel)
}
