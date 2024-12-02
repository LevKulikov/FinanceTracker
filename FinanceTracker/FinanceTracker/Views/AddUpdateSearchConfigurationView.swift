//
//  AddUpdateSearchConfigurationView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 02.12.2024.
//

import SwiftUI

struct AddUpdateSearchConfigurationView: View {
    private let configuration: SearchConfiguration?
    private let balanceAccounts: [BalanceAccount]
    private let categories: [Category]
    private let tags: [Tag]
    private let saveButtonAction: (SearchConfiguration) -> Void
    @State private var filterTransactionType: TransactionFilterTypes = .both
    @State private var filterBalanceAccount: BalanceAccount?
    @State private var filterCategory: Category?
    @State private var filterTags: [Tag] = []
    @State private var dateFilterType: DateFilterType = .month
    @State private var filterDate: Date = .now
    @State private var filterDateStart: Date = .now
    @State private var filterDateEnd: Date = .now
    
    private var filterCategories: [Category] {
        guard filterTransactionType != .both else { return categories }
        
        return categories.filter { category in
            switch filterTransactionType {
            case .both:
                return true
            case .spending:
                return category.type == .spending
            case .income:
                return category.type == .income
            }
        }
    }
    private var buttonTitleAndIcon: (String, String) {
        if configuration == nil {
            return (String(localized: "Add"), "plus")
        }
        return (String(localized: "Update"), "pencil.and.outline")
    }
    
    init(configuration: SearchConfiguration?, balanceAccounts: [BalanceAccount], categories: [Category], tags: [Tag], saveButtonAction: @escaping (SearchConfiguration) -> Void) {
        self.configuration = configuration
        self.saveButtonAction = saveButtonAction
        self.balanceAccounts = balanceAccounts
        self.categories = categories
        self.tags = tags
        if let configuration {
            self._filterTransactionType = .init(wrappedValue: configuration.filterTransactionType)
            self._filterBalanceAccount = .init(wrappedValue: configuration.filterBalanceAccount)
            self._filterCategory = .init(wrappedValue: configuration.filterCategory)
            self._filterTags = .init(wrappedValue: configuration.filterTags)
            self._dateFilterType = .init(wrappedValue: configuration.dateFilterType)
            self._filterDate = .init(wrappedValue: configuration.filterDate)
            self._filterDateStart = .init(wrappedValue: configuration.filterDateStart)
            self._filterDateEnd = .init(wrappedValue: configuration.filterDateEnd)
        }
    }
    
    var body: some View {
        List {
            dateFilterRow
            
            transactionTypeFilterRow
            
            balanceAccountFilterRow
            
            categoryFilterRow
            
            tagsFilterRow
            
            Section {
                Rectangle()
                    .fill(.clear)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .overlay(alignment: .bottom) {
            addUpdateButton
        }
        .onChange(of: filterTransactionType) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if let filterCategoryType = filterCategory?.type, let selectedType = newValue.binaryTransactionType {
                if filterCategoryType != selectedType {
                    filterCategory = nil
                }
            }
        }
    }
    
    private var dateFilterRow: some View {
        HStack {
            Menu(dateFilterType == .customDateRange ? String(localized: "DR") : String(localized: dateFilterType.rawValue), systemImage: "chevron.up.chevron.down") {
                Picker("Date type", selection: $dateFilterType) {
                    ForEach(DateFilterType.allCases) { dateType in
                        Text(dateType.rawValue)
                            .tag(dateType)
                    }
                }
            }
            .foregroundStyle(.primary)
            .hoverEffect(.highlight)
            
            Spacer()
            
            switch dateFilterType {
            case .day:
                DatePicker("One day picker", selection: $filterDate, in: FTAppAssets.availableDateRange, displayedComponents: .date)
                    .labelsHidden()
            case .week:
                DatePicker("Week picker", selection: $filterDate, in: FTAppAssets.availableDateRange, displayedComponents: .date)
                    .labelsHidden()
            case .month:
                MonthYearPicker(date: $filterDate, dateRange: FTAppAssets.availableDateRange, components: .monthYear)
            case .year:
                MonthYearPicker(date: $filterDate, dateRange: FTAppAssets.availableDateRange, components: .year)
            case .customDateRange:
                DateRangePicker(startDate: $filterDateStart, endDate: $filterDateEnd, dateRange: FTAppAssets.availableDateRange)
            }
        }
        .listRowInsets(dateFilterType == .customDateRange ? EdgeInsets() : nil)
    }
    
    private var transactionTypeFilterRow: some View {
        HStack {
            Text("Type")
            
            Spacer()
            
            Menu(String(localized: filterTransactionType.rawValue)) {
                Picker("Transaction type", selection: $filterTransactionType) {
                    ForEach(TransactionFilterTypes.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
            }
            .modifier(RoundedRectMenu())
        }
    }
    
    private var balanceAccountFilterRow: some View {
        HStack {
            Text("Balance Account")
                .layoutPriority(1)
            
            Spacer()
            
            Menu(filterBalanceAccount?.name ?? String(localized: "All")) {
                Picker("Balance account", selection: $filterBalanceAccount) {
                    ForEach(balanceAccounts) { balanceAccount in
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
                    filterBalanceAccount = nil
                }
            }
            .modifier(RoundedRectMenu())
        }
    }
    
    private var categoryFilterRow: some View {
        HStack {
            Text("Category")
                .layoutPriority(1)
            
            Spacer()
            
            Menu(filterCategory?.name ?? String(localized: "All")) {
                Picker("Categories", selection: $filterCategory) {
                    ForEach(filterCategories) { category in
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
                    filterCategory = nil
                }
            }
            .modifier(RoundedRectMenu())
        }
    }
    
    private var tagsFilterRow: some View {
        VStack {
            HStack {
                Text("Tags")
                
                Spacer()
                
                if !filterTags.isEmpty {
                    Button("Clear selection") {
                        filterTags = []
                    }
                    .hoverEffect(.highlight)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(tags) { tag in
                        let tagIdAdded = filterTags.contains(tag)
                        
                        Text("# \(tag.name)")
                            .foregroundStyle(tagIdAdded ? .primary : .secondary)
                            .bold(tagIdAdded)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(tag.color.opacity(tagIdAdded ? 0.4 : 0.15))
                            }
                            .hoverEffect(.highlight)
                            .onTapGesture {
                                addRemoveTag(tag)
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private var addUpdateButton: some View {
        Button {
            addUpdateButtonPressed()
        } label: {
            Label(buttonTitleAndIcon.0, systemImage: buttonTitleAndIcon.1)
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
    private func addRemoveTag(_ tag: Tag) {
        if filterTags.contains(tag) {
            withAnimation {
                filterTags.removeAll {
                    $0 == tag
                }
            }
        } else {
            withAnimation {
                filterTags.append(tag)
            }
        }
    }
    
    private func addUpdateButtonPressed() {
        if let configuration {
            let id = configuration.id
            let copyUpdateConfiguration = SearchConfiguration(
                id: id,
                filterTransactionType: filterTransactionType,
                filterBalanceAccount: filterBalanceAccount,
                filterCategory: filterCategory,
                filterTags: filterTags,
                dateFilterType: dateFilterType,
                filterDate: filterDate,
                filterDateStart: filterDateStart,
                filterDateEnd: filterDateEnd
            )
            saveButtonAction(copyUpdateConfiguration)
        } else {
            let newConfiguration = SearchConfiguration(
                filterTransactionType: filterTransactionType,
                filterBalanceAccount: filterBalanceAccount,
                filterCategory: filterCategory,
                filterTags: filterTags,
                dateFilterType: dateFilterType,
                filterDate: filterDate,
                filterDateStart: filterDateStart,
                filterDateEnd: filterDateEnd
            )
            saveButtonAction(newConfiguration)
        }
    }
}

#Preview {
    let config = SearchConfiguration()
    
    AddUpdateSearchConfigurationView(configuration: nil, balanceAccounts: [], categories: [], tags: []) { _ in
        
    }
}
