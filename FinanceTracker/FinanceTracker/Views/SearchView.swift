//
//  SearchView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 27.06.2024.
//

import SwiftUI

struct SearchView: View {
    //MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var namespace
    @StateObject private var viewModel: SearchViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showMoreFilters = false
    @State private var searchIsPreseneted: Bool = false
    @State private var showTransaction: Transaction?
    
    //MARK: - Initializer
    init(viewModel: SearchViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                headerView
                
                showFilterButton
                    .padding(.vertical)
                
                ForEach(viewModel.filteredTransactionGroups) { transGroup in
                    SearchSection(transactionGroupData: transGroup) { transaction in
                        showTransaction = transaction
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
            .navigationTitle("Search")
            .overlay {
                if viewModel.isListCalculating {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .onChange(of: searchIsPreseneted) {
                viewModel.hideTabBar(searchIsPreseneted)
            }
            .fullScreenCover(item: $showTransaction) { transaction in
                viewModel.getTransactionView(for: transaction, namespace: namespace)
            }
//            .onAppear {
//                viewModel.refetchData()
//            }
        }
        .searchable(text: $viewModel.searchText, isPresented: $searchIsPreseneted, prompt: Text("Any text or number"))
    }
    
    //MARK: - Computed View props
    private var headerView: some View {
        VStack {
            HStack {
                Menu(viewModel.dateFilterType == .customDateRange ? "DR" : viewModel.dateFilterType.rawValue) {
                    Picker("Date type", selection: $viewModel.dateFilterType) {
                        ForEach(DateFilterType.allCases, id: \.rawValue) { dateType in
                            Text(dateType.rawValue)
                                .tag(dateType)
                        }
                    }
                }
                .modifier(RoundedRectMenu())
                
                Spacer()
                
                switch viewModel.dateFilterType {
                case .day:
                    DatePicker("One day picker", selection: $viewModel.filterDate, displayedComponents: .date)
                        .labelsHidden()
                case .week:
                    DatePicker("Week picker", selection: $viewModel.filterDate, displayedComponents: .date)
                        .labelsHidden()
                case .month:
                    MonthYearPicker(date: $viewModel.filterDate, dateRange: FTAppAssets.availableDateRange, components: .monthYear)
                case .year:
                    MonthYearPicker(date: $viewModel.filterDate, dateRange: FTAppAssets.availableDateRange, components: .year)
                case .customDateRange:
                    DateRangePicker(startDate: $viewModel.filterDateStart, endDate: $viewModel.filterDateEnd, dateRange: FTAppAssets.availableDateRange)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
    }
    
    private var showFilterButton: some View {
        VStack {
            if !showMoreFilters {
                Button {
                    withAnimation {
                        showMoreFilters = true
                    }
                } label: {
                    Text("Show more filter")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemFill))
                        }
                        .matchedGeometryEffect(id: "moreFilterBackground", in: namespace)
                }
            } else {
                HStack {
                    Text("Filters")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Hide", systemImage: "chevron.up") {
                        withAnimation {
                            showMoreFilters = false
                        }
                    }
                    .font(.caption)
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                }
                .transition(.blurReplace)
                
                filtersView
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    private var filtersView: some View {
        VStack {
            HStack {
                Text("Type")
                
                Spacer()
                
                Menu(viewModel.filterTransactionType.rawValue) {
                    Picker("Transaction type", selection: $viewModel.filterTransactionType) {
                        ForEach(TransactionFilterTypes.allCases, id: \.rawValue) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                }
                .modifier(RoundedRectMenu())
            }
            
            Divider()
            
            HStack {
                Text("Balance Account")
                    .layoutPriority(1)
                
                Spacer()
                
                Menu(viewModel.filterBalanceAccount?.name ?? "All") {
                    Picker("Balance account", selection: $viewModel.filterBalanceAccount) {
                        ForEach(viewModel.allBalanceAccounts) { balanceAccount in
                            HStack {
                                Text(balanceAccount.name)
                                
                                if let uiImage = FTAppAssets.iconUIImage(name: balanceAccount.iconName) {
                                    Image(uiImage: uiImage)
                                } else {
                                    Image(systemName: "xmark")
                                }
                            }
                            .tag(Optional(balanceAccount))
                        }
                    }
                    
                    Button("All") {
                        viewModel.filterBalanceAccount = nil
                    }
                }
                .modifier(RoundedRectMenu())
            }
            
            Divider()
            
            HStack {
                Text("Category")
                    .layoutPriority(1)
                
                Spacer()
                
                Menu(viewModel.filterCategory?.name ?? "All") {
                    Picker("Categories", selection: $viewModel.filterCategory) {
                        ForEach(viewModel.filterCategories) { category in
                            HStack {
                                Text(category.name)
                                
                                if let uiImage = FTAppAssets.iconUIImage(name: category.iconName) {
                                    Image(uiImage: uiImage)
                                } else {
                                    Image(systemName: "xmark")
                                }
                            }
                            .tag(Optional(category))
                        }
                    }
                    
                    Button("All") {
                        viewModel.filterCategory = nil
                    }
                }
                .modifier(RoundedRectMenu())
            }
            
            Divider()
            
            HStack {
                Text("Tags")
                
                Spacer()
                
                if !viewModel.filterTags.isEmpty {
                    Button("Clear selection") {
                        viewModel.filterTags = []
                    }
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.allTags) { tag in
                        let tagIdAdded = viewModel.filterTags.contains(tag)
                        
                        Text("# \(tag.name)")
                            .foregroundStyle(tagIdAdded ? .primary : .secondary)
                            .bold(tagIdAdded)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(tag.color.opacity(tagIdAdded ? 0.4 : 0.15))
                            }
                            .onTapGesture {
                                viewModel.addRemoveTag(tag)
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(.systemBackground) : Color(.systemGray6))
                .matchedGeometryEffect(id: "moreFilterBackground", in: namespace)
        }
    }
    
    //MARK: - Methods
    
}

struct RoundedRectMenu: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .buttonStyle(.bordered)
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = SearchViewModel(dataManager: dataManger)
    
    return SearchView(viewModel: viewModel)
}
