//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: StatisticsViewModel
    @State private var showTagsView = false
    private var windowWidth: CGFloat {
        FTAppAssets.getWindowSize().width
    }
    private var pieChartHeight: CGFloat {
        return 350
    }
    
    //MARK: - Init
    init(viewModel: StatisticsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if windowWidth <= FTAppAssets.maxCustomSheetWidth {
                        totalValueSection
                            .padding(.bottom)
                        
                        pieChartSection
                            .padding(.bottom)
                    } else {
                        HStack {
                            totalValueSection
                            
                            pieChartSection
                        }
                        .frame(maxHeight: pieChartHeight)
                    }
                    
                    barChartSection
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 60)
                }
                .padding()
            }
            .refreshable {
                viewModel.refreshData()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isFetchingData {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            viewModel.refreshData()
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .sheet(isPresented: $showTagsView) {
                viewModel.getTagsView()
            }
        }
    }
    
    //MARK: - Computed View Props
    private var totalValueSection: some View {
        VStack {
            HStack {
                Text("Total balance")
                    .font(.title2)
                    .bold()
                    .layoutPriority(1)
                
                Spacer()
                
                Menu(viewModel.balanceAccountToFilter.name) {
                    Picker("Picker title", selection: $viewModel.balanceAccountToFilter) {
                        ForEach(viewModel.balanceAccounts) { balanceAccount in
                            HStack {
                                Text(balanceAccount.name)
                                
                                if let uiImage = FTAppAssets.iconUIImage(name: balanceAccount.iconName) {
                                    Image(uiImage: uiImage)
                                } else {
                                    Image(systemName: "xmark")
                                }
                            }
                            .tag(balanceAccount)
                        }
                    }
                }
                .lineLimit(1)
                .buttonStyle(.bordered)
            }
            
            HStack(alignment: .bottom) {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.totalForBalanceAccount) ?? "Unable to get")
                    .font(.title)
                    .underline(color: .secondary)
                
                Text(viewModel.balanceAccountToFilter.currency)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            Divider()
            
            tagsStatSection
            
            if windowWidth > FTAppAssets.maxCustomSheetWidth {
                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        }
        .frame(maxHeight: pieChartHeight)
    }
    
    private var tagsStatSection: some View {
        VStack {
            HStack {
                Text("Tags stats")
                    .font(.title2)
                    .bold()
                
                if viewModel.tagsDataIsCalculating {
                    ProgressView()
                        .padding(.leading, 5)
                }
                
                Spacer()
                
                Menu(viewModel.transactionTypeForTags.rawValue) {
                    Picker("Transaction type for tags picker", selection: $viewModel.transactionTypeForTags) {
                        ForEach(TransactionsType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if !viewModel.allTags.isEmpty {
                if !viewModel.tagsTotalData.isEmpty {
                    ScrollView {
                        TagsLineChart(tagData: viewModel.tagsTotalData)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    noOneTagIsUsedView
                }
            } else {
                noSavedTagsView
            }
        }
    }
    
    private var noSavedTagsView: some View {
        VStack {
            Text("You do not have any saved tag.")
                .foregroundStyle(.secondary)
            
            Text("It is good opportunity to try!")
                .foregroundStyle(.secondary)
            
            Button("Create tag") {
                showTagsView.toggle()
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)
        }
    }
    
    private var noOneTagIsUsedView: some View {
        VStack {
            Text("You do not have \(viewModel.transactionTypeForTags.rawValue) with tags")
        }
        .foregroundStyle(.secondary)
    }
    
    private var pieChartSection: some View {
        VStack {
            HStack {
                Text("Pie chart")
                    .font(.title2)
                    .bold()
                
                if viewModel.pieDataIsCalculating {
                    ProgressView()
                        .padding(.leading, 5)
                }
                
                Spacer()
                
                Menu(viewModel.pieChartTransactionType.rawValue) {
                    Picker("Pie chart picker", selection: $viewModel.pieChartTransactionType) {
                        ForEach(TransactionsType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            TransactionPieChart(transactionGroups: viewModel.pieChartTransactionData)
                .padding(.bottom)
            
            pieChartMenuDatePickerView
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        }
        .frame(height: pieChartHeight)
    }
    
    private var pieChartMenuDatePickerView: some View {
        VStack {
            HStack {
                Menu(viewModel.pieChartMenuDateFilterSelected.rawValue, systemImage: "chevron.up.chevron.down") {
                    Picker("Pie chart date type picker", selection: $viewModel.pieChartMenuDateFilterSelected) {
                        ForEach(PieChartDateFilter.allCases, id: \.rawValue) { dateFilterType in
                            Text(dateFilterType.rawValue)
                                .tag(dateFilterType)
                        }
                    }
                    
                    Button("Default filters", systemImage: "arrowshape.turn.up.backward") {
                        viewModel.setPieChartDateFiltersToDefault()
                    }
                }
                .foregroundStyle(.primary)
                
                Spacer()
                
                switch viewModel.pieChartMenuDateFilterSelected {
                case .day:
                    DatePicker("One day date picker", selection: $viewModel.pieChartDate, in: FTAppAssets.availableDateRange, displayedComponents: .date)
                        .labelsHidden()
                case .month:
                    MonthYearPicker(date: $viewModel.pieChartDate, dateRange: FTAppAssets.availableDateRange, components: .monthYear)
                case .year:
                    MonthYearPicker(date: $viewModel.pieChartDate, dateRange: FTAppAssets.availableDateRange, components: .year)
                case .dateRange:
                    EmptyView()
                case .allTime:
                    EmptyView()
                }
            }
            
            if case .dateRange = viewModel.pieChartMenuDateFilterSelected {
                HStack {
                    Button("Back", systemImage: "chevron.left") {
                        viewModel.moveDateRange(direction: .back)
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(!viewModel.pieDateRangeCanBeMovedBack)
                    
                    Spacer()
                    
                    DateRangePicker(startDate: $viewModel.pieChartDateStart, endDate: $viewModel.pieChartDateEnd, dateRange: FTAppAssets.availableDateRange)
                    
                    Spacer()
                    
                    Button("Forward", systemImage: "chevron.right") {
                        viewModel.moveDateRange(direction: .forward)
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(!viewModel.pieDateRangeCanBeMovedForward)
                }
                .padding(.top)
            }
        }
    }
    
    private var barChartSection: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Bar chart")
                            .font(.title2)
                            .bold()
                        
                        if viewModel.barDataIsCalculating {
                            ProgressView()
                                .padding(.leading, 5)
                        }
                    }
                    
                    Text("Scroll to get more info")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu(viewModel.barChartTransactionTypeFilter.rawValue) {
                    Picker("Bar chart picker", selection: $viewModel.barChartTransactionTypeFilter) {
                        ForEach(TransactionFilterTypes.allCases, id: \.rawValue) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            TransactionBarChart(
                transactionsData: viewModel.barChartTransactionData,
                perDate: $viewModel.barChartPerDateFilter,
                transactionType: $viewModel.barChartTransactionTypeFilter
            )
            .frame(height: 300)
            .padding(.bottom)
            
            HStack {
                Menu(viewModel.barChartPerDateFilter.rawValue, systemImage: "chevron.up.chevron.down") {
                    Picker("Bar chart date sride type picker", selection: $viewModel.barChartPerDateFilter) {
                        ForEach(BarChartPerDateFilter.allCases, id: \.rawValue) { dateFilterType in
                            Text(dateFilterType.rawValue)
                                .tag(dateFilterType)
                        }
                    }
                }
                .foregroundStyle(.primary)
                
                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        }
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = StatisticsViewModel(dataManager: dataManger)
    
    return StatisticsView(viewModel: viewModel)
}
