//
//  ProvidedStatisticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 05.08.2024.
//

import SwiftUI

struct ProvidedStatisticsView: View {
    //MARK: - Properties
    @StateObject private var viewModel: ProvidedStatisticsViewModel
    @Environment(\.colorScheme) private var colorScheme
    private var pieChartHeight: CGFloat {
        return 280
    }
    private var backgroundColor: Color {
        colorScheme == .light ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }
    private var cellColor: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }
    private var outerCellModifier: some ViewModifier {
        StatisticCellModifier(
            cornerRadius: 15,
            backgroundColor: cellColor
        )
    }
    private var innerCellModifier: some ViewModifier {
        StatisticCellModifier(
            cornerRadius: 10,
            backgroundColor: backgroundColor
        )
    }
    
    //MARK: - Initializer
    init(viewModel: ProvidedStatisticsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    totalsSection
                    
                    if viewModel.showStatValuesSection {
                        statValuesView
                    }
                    
                    pieChartSection
                    
                    barChartSection
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .background {
                backgroundColor.ignoresSafeArea()
            }
        }
    }
    
    //MARK: - Computed View Properties
    private var totalsSection: some View {
        VStack {
            HStack {
                Text("Total")
                    .font(.title2)
                    .bold()
                
                Text(viewModel.currency)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            ForEach(viewModel.totalValues) { totalValue in
                HStack {
                    HStack {
                        Text(formatNumber(totalValue.value))
                        if let currency = viewModel.currencyPrecised {
                            Text(currency.symbol)
                        }
                        
                        Text(totalValue.type.rawValue)
                            .foregroundStyle(totalValue.type.color)
                            .layoutPriority(1)
                    }
                    .modifier(innerCellModifier)
                    
                    Spacer()
                }
            }
        }
        .modifier(outerCellModifier)
    }
    
    private var statValuesView: some View {
        VStack {
            HStack {
                if let middleValue = viewModel.middleValue {
                    HStack {
                        Text("Middle")
                            .layoutPriority(1)
                            .foregroundStyle(.secondary)
                        Text(formatNumber(middleValue.value))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .modifier(innerCellModifier)
                    .lineLimit(1)
                }
                
                if viewModel.providedTransactionType == .both {
                    Menu(String(localized: viewModel.statsValuesTransactionType.localizedString)) {
                        Picker("Stats values picker", selection: $viewModel.statsValuesTransactionType) {
                            ForEach(TransactionsType.allCases) { type in
                                Text(type.localizedString)
                                    .tag(type)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .hoverEffect(.highlight)
                }
            }
            
            HStack {
                if let minValue = viewModel.minValue {
                    HStack {
                        Text("Min")
                            .layoutPriority(1)
                            .foregroundStyle(.secondary)
                        Text(formatNumber(minValue.value))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .modifier(innerCellModifier)
                    .lineLimit(1)
                }
                
                if let maxValue = viewModel.maxValue {
                    HStack {
                        Text("Max")
                            .foregroundStyle(.secondary)
                            .layoutPriority(1)
                        Text(formatNumber(maxValue.value))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .modifier(innerCellModifier)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .modifier(outerCellModifier)
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
                
                if viewModel.providedTransactionType == .both {
                    Menu(String(localized: viewModel.pieChartTransactionType.localizedString)) {
                        Picker("Pie chart picker", selection: $viewModel.pieChartTransactionType) {
                            ForEach(TransactionsType.allCases) { type in
                                Text(type.localizedString)
                                    .tag(type)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .hoverEffect(.highlight)
                }
            }
            
            TransactionPieChart(transactionGroups: viewModel.pieChartTransactionData)
            .padding(.bottom)
        }
        .modifier(outerCellModifier)
        .frame(height: pieChartHeight)
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
                
                if viewModel.providedTransactionType == .both {
                    Menu(String(localized: viewModel.barChartTransactionTypeFilter.rawValue)) {
                        Picker("Bar chart picker", selection: $viewModel.barChartTransactionTypeFilter) {
                            ForEach(TransactionFilterTypes.allCases) { type in
                                Text(type.rawValue)
                                    .tag(type)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .hoverEffect(.highlight)
                }
            }
            
            TransactionBarChart(
                transactionsData: viewModel.barChartTransactionData,
                perDate: $viewModel.barChartPerDateFilter,
                transactionType: $viewModel.barChartTransactionTypeFilter,
                xScaleEndDate: viewModel.transactionMaxDate == nil ? .now : viewModel.transactionMaxDate!
            )
            .frame(height: 300)
            .padding(.bottom)
            
            HStack {
                Menu(String(localized: viewModel.barChartPerDateFilter.rawValue), systemImage: "chevron.up.chevron.down") {
                    Picker("Bar chart date sride type picker", selection: $viewModel.barChartPerDateFilter) {
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
        .modifier(outerCellModifier)
    }
    
    //MARK: - Methods
    private func formatNumber<T: Numeric>(_ number: T) -> String {
        FTFormatters.numberFormatterWithDecimals.string(for: number) ?? "Err"
    }
}

struct StatisticCellModifier: ViewModifier {
    let cornerRadius: CGFloat
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            }
    }
}

#Preview {
    let viewModel = ProvidedStatisticsViewModel(transactions: [], currency: "RUB")
    return ProvidedStatisticsView(viewModel: viewModel)
}
