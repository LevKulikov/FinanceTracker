//
//  AdvancedAnalyticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 02.12.2024.
//

import SwiftUI

struct AdvancedAnalyticsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: AdvancedAnalyticsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddingFilterView: Bool = false
    @State private var updatedConfiguration: SearchConfiguration?
    @State private var windowSize: CGSize = FTAppAssets.getWindowSize()
    @State private var removeAllAlert: Bool = false
    @State private var saveConfigsAlert: Bool = false
    @State private var saveConfigsError: Bool = false
    private let userDevice = FTAppAssets.currentUserDevise
    private var isIpad: Bool {
        FTAppAssets.currentUserDevise == .pad
    }
    
    //MARK: - Initializer
    init(viewModel: AdvancedAnalyticsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    //MARK: - Computed View Properties
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.searchConfigurations.isEmpty {
                    noFilterAddedView
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: (windowSize.width / 2) - 20))]) {
                    ForEach(viewModel.searchConfigurations) { config in
                        ConfigurationCell(config)
                    }
                }
                .padding(.horizontal, 10)
                
                Rectangle()
                    .fill(.clear)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .navigationTitle("Advanced Analytics")
            .toolbar {
                if viewModel.isLoadingOtherData {
                    ProgressView()
                } else {
                    Button("Save filters", systemImage: "square.and.arrow.down.on.square") {
                        saveConfigsAlert.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .disabled(viewModel.isLoadingTransactions)
                    
                    if !viewModel.searchConfigurations.isEmpty {
                        Button("Delete all filters", systemImage: "trash") {
                            removeAllAlert.toggle()
                        }
                        .labelStyle(.iconOnly)
                        .disabled(viewModel.isLoadingTransactions)
                    }
                    
                    Button("Add filter", systemImage: "plus") {
                        showAddingFilterView.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .disabled(viewModel.isLoadingTransactions)
                }
            }
            .overlay(alignment: .bottom) {
                if !viewModel.searchConfigurations.isEmpty {
                    analyticsButton
                        .offset(y: userDevice == .phone ? 0 : -60)
                }
            }
            .overlay {
                if viewModel.isLoadingTransactions {
                    transactionsLoadingView
                }
            }
            .onAppear {
                viewModel.fetchOtherData()
            }
            .onDisappear {
                viewModel.cancelFetching()
            }
            .sheet(isPresented: $showAddingFilterView) {
                AddUpdateSearchConfigurationView(configuration: nil, balanceAccounts: viewModel.allBalanceAccounts, categories: viewModel.allCategories, tags: viewModel.allTags) { config in
                    viewModel.addConfiguration(config)
                    showAddingFilterView.toggle()
                }
            }
            .sheet(item: $updatedConfiguration) { config in
                AddUpdateSearchConfigurationView(configuration: config, balanceAccounts: viewModel.allBalanceAccounts, categories: viewModel.allCategories, tags: viewModel.allTags) { configuration in
                    viewModel.updateConfiguration(configuration)
                    updatedConfiguration = nil
                }
            }
            .sheet(isPresented: $viewModel.showAnalytics) {
                viewModel.getAnalyticsPage()
            }
            .alert("No transactions found", isPresented: $viewModel.noTransactions) {
                Button("Ok") {}
            } message: {
                Text("Try to change filters to get more transactions")
            }
            .alert("Remove all filters?", isPresented: $removeAllAlert) {
                Button("No", role: .cancel) {}
                Button("Yes", role: .destructive) {
                    viewModel.removeAllConfigurations()
                }
            } message: {
                Text("This will not affect saved filters")
            }
            .alert("Select currency", isPresented: $viewModel.showCurrencySelection) {
                ForEach(viewModel.currencies, id: \.self) { currency in
                    Button(currency) {
                        viewModel.selectCurrency(currency)
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .alert("Save filters?", isPresented: $saveConfigsAlert) {
                Button("Save") {
                    viewModel.saveConfiguration { result in
                        switch result {
                        case .failure:
                            saveConfigsError.toggle()
                        case .success:
                            break
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                if viewModel.searchConfigurations.isEmpty {
                    Text("Saving empty filters deletes previously saved filters")
                } else {
                    Text("The next time you start the application, the filters will be loaded from memory")
                }
            }
            .alert("Can't save filters", isPresented: $saveConfigsError) {
                Button("Ok") {}
            } message: {
                Text("Something went wrong during saving the filters. Please try again later")
            }
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                windowSize = newValue
            }
        }
    }
    
    private var noFilterAddedView: some View {
        ContentUnavailableView {
            Label("No filters added", systemImage: "tray")
        } description: {
            Text("Add any number of filters to search for transactions of interest and get analytics on them. Analytics will reflect unique transactions")
        } actions: {
            Button("Add filter") {
                showAddingFilterView.toggle()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var analyticsButton: some View {
        Button {
            viewModel.getAnalytics()
        } label: {
            Label("Get analytics", systemImage: "chart.bar.xaxis")
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(.blue)
                }
        }
        .disabled(viewModel.isLoadingTransactions || viewModel.isLoadingOtherData)
        .hoverEffect(.lift)
        .offset(y: -5)
    }
    
    private var transactionsLoadingView: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .foregroundStyle(.secondary)
                .padding(.bottom)
                .padding(.bottom)
            
            Button("Cancel") {
                viewModel.cancelFetching()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: 200, maxHeight: 200)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .light ? Color(.systemBackground) : Color(.systemGray6))
        }
        .padding()
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
        .animation(.default, value: viewModel.isLoadingTransactions)
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func ConfigurationCell(_ configuration: SearchConfiguration) -> some View {
        VStack(alignment: .leading) {
            Text(getDateText(configuration))
                .foregroundStyle(.secondary)
            
            Text(configuration.filterTransactionType.rawValue)
                .foregroundStyle(configuration.filterTransactionType.color)
            
            Text(configuration.filterBalanceAccount?.name ?? String(localized: "All accounts"))
                .foregroundStyle(configuration.filterBalanceAccount?.color ?? .secondary)
            
            Text(configuration.filterCategory?.name ?? String(localized: "All categories"))
                .foregroundStyle(configuration.filterCategory?.color ?? .secondary)
            
            if configuration.filterTags.isEmpty {
                Text("0 tags")
                    .foregroundStyle(.secondary)
            } else {
                let firstTag = configuration.filterTags.first!
                Text("\(firstTag.name)")
                    .foregroundStyle(firstTag.color)
                +
                Text(configuration.filterTags.count > 1 ? " + \(configuration.filterTags.count - 1)" : "")
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .font(.footnote)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .stroke(.secondary, style: .init(lineWidth: 1))
        }
        .onTapGesture {
            updatedConfiguration = configuration
        }
        .contentShape([.hoverEffect, .contextMenuPreview], RoundedRectangle(cornerRadius: 12.0))
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                viewModel.removeConfiguration(configuration)
            }
            
            Button("Duplicate", systemImage: "document.on.document") {
                viewModel.duplicateConfiguration(configuration)
            }
        }
    }
    
    private func getDateText(_ configuration: SearchConfiguration) -> String {
        let date = configuration.filterDate
        let dateComponents = Calendar.current.dateComponents([.weekOfMonth, .month, .year], from: date)
        
        switch configuration.dateFilterType {
        case .day:
            return date.formatted(date: .abbreviated, time: .omitted)
        case .week:
            return "\(String(localized: "Week")) \(dateComponents.weekOfMonth ?? 0), \(date.month) \(dateComponents.year ?? 0)"
        case .month:
            return "\(date.month) \(dateComponents.year ?? 0)"
        case .year:
            return "\(dateComponents.year ?? 0)"
        case .customDateRange:
            let startDateString = configuration.filterDateStart.formatted(date: .abbreviated, time: .omitted)
            let endDateString = configuration.filterDateEnd.formatted(date: .abbreviated, time: .omitted)
            return "\(startDateString) - \(endDateString)"
        }
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AdvancedAnalyticsViewModel(dataManager: dataManager)
    AdvancedAnalyticsView(viewModel: viewModel)
}
