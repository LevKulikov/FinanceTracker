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
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: StatisticsViewModel
    @State private var showTagsView = false
    @State private var showStatitsticsSettings = false
    @State private var showTransactionListWithData: TransactionListUIData?
    private var windowWidth: CGFloat {
        FTAppAssets.getWindowSize().width
    }
    private var pieChartHeight: CGFloat {
        return viewModel.lightWeightStatistics ? 290 : 350
    }
    private var backgroundColor: Color {
        colorScheme == .light ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }
    private var cellColor: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
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
                        topStatisticsSection
                            .padding(.bottom)
                        
                        pieChartSection
                            .padding(.bottom)
                    } else {
                        HStack {
                            topStatisticsSection
                            
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
                if viewModel.isFetchingData {
                    ProgressView()
                        .controlSize(.regular)
                        .scaleEffect(1.3, anchor: .trailing)
                } else {
                    Button("Settings", systemImage: "gear") {
                        showStatitsticsSettings = true
                    }
                    .labelStyle(.iconOnly)
                    .popover(isPresented: $showStatitsticsSettings) {
                        settingsPopoverView
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
            .navigationTitle("Statistics")
            .sheet(isPresented: $showTagsView) {
                viewModel.getTagsView()
            }
            .sheet(item: $showTransactionListWithData) {
                viewModel.refreshDataIfNeeded()
            } content: { transactionListData in
                viewModel.getTransactionListView(transactions: transactionListData.transactions, title: transactionListData.title)
            }
            .onAppear {
                viewModel.refreshDataIfNeeded()
            }
            .background(content: { backgroundColor.ignoresSafeArea() })
        }
    }
    
    //MARK: - Computed View Props
    private var settingsPopoverView: some View {
        VStack {
            Text("If the statistics take a long time to load, you can choose to display a light version. The light version of the statistics is faster, but it does not show the current account balance and also shows a smaller interval on the bar chart")
                .foregroundStyle(.secondary)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cellColor)
                }
                .frame(height: 220)
            
            Toggle("Light version", isOn: $viewModel.lightWeightStatistics)
                .padding(.horizontal)
                .bold()
        }
        .padding()
        .background(backgroundColor)
    }
    
    private var topStatisticsSection: some View {
        VStack {
            if viewModel.lightWeightStatistics {
                lightWeightStatisticsFilters
                    .padding(.bottom)
            } else {
                totalValueView
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
                .fill(cellColor)
        }
        .frame(maxHeight: pieChartHeight)
    }
    
    private var totalValueView: some View {
        VStack {
            HStack {
                Text("Total balance")
                    .font(.title2)
                    .bold()
                    .layoutPriority(1)
                
                if viewModel.totalIsCalculating {
                    ProgressView()
                        .padding(.leading, 5)
                }
                
                Spacer()
                
                Menu(viewModel.balanceAccountToFilter.name) {
                    Picker("Balance Accounts", selection: $viewModel.balanceAccountToFilter) {
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
                .hoverEffect(.highlight)
            }
            
            HStack(alignment: .bottom) {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: viewModel.totalForBalanceAccount) ?? "Unable to get")
                    .font(.title)
                    .underline(color: .secondary)
                
                Text(viewModel.balanceAccountToFilter.currency)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var lightWeightStatisticsFilters: some View {
        VStack {
            HStack {
                Text("Balance Account")
                    .bold()
                    .font(.title2)
                
                Spacer()
                
                Menu(viewModel.balanceAccountToFilter.name) {
                    Picker("Balance Accounts", selection: $viewModel.balanceAccountToFilter) {
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
                .hoverEffect(.highlight)
            }
            
            HStack {
                Menu(String(localized: viewModel.lightWeightDateType.rawValue), systemImage: "chevron.up.chevron.down") {
                    Picker("Select date type", selection: $viewModel.lightWeightDateType) {
                        ForEach(DateFilterType.allCases) { dateFilterType in
                            Text(dateFilterType.rawValue)
                                .tag(dateFilterType)
                        }
                    }
                }
                .foregroundStyle(.primary)
                .hoverEffect(.highlight)
                
                Spacer()
                
                switch viewModel.lightWeightDateType {
                case .day:
                    DatePicker("One day date picker", selection: $viewModel.lightWeightDate, in: FTAppAssets.availableDateRange, displayedComponents: .date)
                        .labelsHidden()
                case .week:
                    DatePicker("Week day picker", selection: $viewModel.lightWeightDate, in: FTAppAssets.availableDateRange, displayedComponents: .date)
                        .labelsHidden()
                case .month:
                    MonthYearPicker(date: $viewModel.lightWeightDate, dateRange: FTAppAssets.availableDateRange, components: .monthYear)
                case .year:
                    MonthYearPicker(date: $viewModel.lightWeightDate, dateRange: FTAppAssets.availableDateRange, components: .year)
                case .customDateRange:
                    EmptyView()
                }
            }
            
            if case .customDateRange = viewModel.lightWeightDateType {
                DateRangePicker(startDate: $viewModel.lightWeightDateStart, endDate: $viewModel.lightWeightDateEnd, dateRange: FTAppAssets.availableDateRange)
                    .padding(.vertical, 5)
            }
        }
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
                
                Menu(String(localized: viewModel.transactionTypeForTags.localizedString)) {
                    Picker("Select transaction type", selection: $viewModel.transactionTypeForTags) {
                        ForEach(TransactionsType.allCases) { type in
                            Text(type.localizedString)
                                .tag(type)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .hoverEffect(.highlight)
            }
            
            if !viewModel.allTags.isEmpty {
                if !viewModel.tagsTotalData.isEmpty {
                    ScrollView {
                        TagsLineChart(tagData: viewModel.tagsTotalData) { tagData in
                            let title: String = "# \(tagData.tag.name)"
                            showTransactionListWithData = TransactionListUIData(transactions: tagData.transactions, title: title)
                        }
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
                .multilineTextAlignment(.center)
            
            Text("It is good opportunity to try!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create tag") {
                showTagsView.toggle()
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)
            .hoverEffect(.highlight)
        }
    }
    
    private var noOneTagIsUsedView: some View {
        VStack {
            Text("You do not have \(viewModel.transactionTypeForTags.localizedString) with tags")
                .multilineTextAlignment(.center)
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
                
                Menu(String(localized: viewModel.pieChartTransactionType.localizedString)) {
                    Picker("Select transaction type", selection: $viewModel.pieChartTransactionType) {
                        ForEach(TransactionsType.allCases) { type in
                            Text(type.localizedString)
                                .tag(type)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .hoverEffect(.highlight)
            }
            
            TransactionPieChart(transactionGroups: viewModel.pieChartTransactionData) { pieChartData in
                let transactions = pieChartData.transactions
                let title = pieChartData.category.name
                showTransactionListWithData = TransactionListUIData(transactions: transactions, title: title)
            }
            .padding(.bottom)
            
            if !viewModel.lightWeightStatistics {
                pieChartMenuDatePickerView
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(cellColor)
        }
        .frame(height: pieChartHeight)
    }
    
    private var pieChartMenuDatePickerView: some View {
        VStack {
            HStack {
                Menu(String(localized: viewModel.pieChartMenuDateFilterSelected.rawValue), systemImage: "chevron.up.chevron.down") {
                    Picker("Select date type", selection: $viewModel.pieChartMenuDateFilterSelected) {
                        ForEach(PieChartDateFilter.allCases) { dateFilterType in
                            Text(dateFilterType.rawValue)
                                .tag(dateFilterType)
                        }
                    }
                    
                    Button("Default filters", systemImage: "arrowshape.turn.up.backward") {
                        viewModel.setPieChartDateFiltersToDefault()
                    }
                }
                .foregroundStyle(.primary)
                .hoverEffect(.highlight)
                
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
                    .hoverEffect(.highlight)
                    .disabled(!viewModel.pieDateRangeCanBeMovedBack)
                    
                    Spacer()
                    
                    DateRangePicker(startDate: $viewModel.pieChartDateStart, endDate: $viewModel.pieChartDateEnd, dateRange: FTAppAssets.availableDateRange)
                    
                    Spacer()
                    
                    Button("Forward", systemImage: "chevron.right") {
                        viewModel.moveDateRange(direction: .forward)
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .hoverEffect(.highlight)
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
                
                Menu(String(localized: viewModel.barChartTransactionTypeFilter.rawValue)) {
                    Picker("Select displayed transactions", selection: $viewModel.barChartTransactionTypeFilter) {
                        ForEach(TransactionFilterTypes.allCases) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .hoverEffect(.highlight)
            }
            
            TransactionBarChart(
                transactionsData: viewModel.barChartTransactionData,
                perDate: $viewModel.barChartPerDateFilter,
                transactionType: $viewModel.barChartTransactionTypeFilter
            )
            .frame(height: 300)
            .padding(.bottom)
            
            HStack {
                Menu(String(localized: viewModel.barChartPerDateFilter.rawValue), systemImage: "chevron.up.chevron.down") {
                    Picker("Select date for bars", selection: $viewModel.barChartPerDateFilter) {
                        ForEach(BarChartPerDateFilter.allCases) { dateFilterType in
                            Text(dateFilterType.rawValue)
                                .tag(dateFilterType)
                        }
                    }
                }
                .foregroundStyle(.primary)
                .hoverEffect(.highlight)
                
                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(cellColor)
        }
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = StatisticsViewModel(dataManager: dataManger)
    
    return StatisticsView(viewModel: viewModel)
}
