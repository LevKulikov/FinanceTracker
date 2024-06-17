//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI

struct StatisticsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: StatisticsViewModel
    
    //MARK: - Init
    init(viewModel: StatisticsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    totalValueSection
                        .padding(.bottom)

                    pieChartSection
                        .padding(.bottom)
                    
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
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        viewModel.refreshData()
                    }
                }
            }
            .navigationTitle("Statistics")
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
                            Text(balanceAccount.name)
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
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        }
    }
    
    private var pieChartSection: some View {
        VStack {
            HStack {
                Text("Pie chart")
                    .font(.title2)
                    .bold()
                
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
                .frame(height: 200)
                .padding(.bottom)
            
            pieChartMenuDatePickerView
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        }
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
            TransactionBarChart(
                transactionsData: viewModel.barChartTransactionData,
                perDate: viewModel.barChartPerDateFilter,
                transactionType: viewModel.barChartTransactionTypeFilter
            )
            .frame(height: 300)
        }
    }
    
    //MARK: - Methods
    
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = StatisticsViewModel(dataManager: dataManger)
    
    return StatisticsView(viewModel: viewModel)
}
