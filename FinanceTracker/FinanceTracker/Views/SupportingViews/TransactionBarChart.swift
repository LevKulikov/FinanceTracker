//
//  TransactionBarChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 15.06.2024.
//

import SwiftUI
import Charts

struct TransactionBarChartData: Identifiable {
    enum TransactionBarChartDataType: String {
        case spending = "Spending"
        case income = "Income"
        case profit = "Profit"
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .spending:
                return .red
            case .income:
                return .green
            case .profit:
                return .blue
            case .unknown:
                return .yellow
            }
        }
    }
    
    let id: String = UUID().uuidString
    let type: TransactionBarChartDataType
    let value: Float
    let date: Date
}

struct TransactionBarChart: View {
    //MARK: Properties
    let transactionsData: [[TransactionBarChartData]]
    @Binding var perDate: BarChartPerDateFilter
    @Binding var transactionType: TransactionFilterTypes
    
    private var maxXVisibleLenth: Int {
        let multiplier = transactionType == .both ? 5 : 10
        let seconds: Int
        switch perDate {
        case .perDay:
            // 86400 seconds in 24 hours
            seconds = 86400
        case .perWeek:
            seconds = 86400 * 7
        case .perMonth:
            seconds = 86400 * 30
        case .perYear:
            seconds = 86400 * 365
        }
        return seconds * multiplier
    }
    private var unit: Calendar.Component {
        switch perDate {
        case .perDay:
            return .day
        case .perWeek:
            return .weekOfYear
        case .perMonth:
            return .month
        case .perYear:
            return .year
        }
    }
    private var componentsToCompare: Set<Calendar.Component> {
        let components: Set<Calendar.Component>
        switch perDate {
        case .perDay:
            components = [.day, .month, .year]
        case .perWeek:
            components = [.weekOfMonth, .month, .year]
        case .perMonth:
            components = [.month, .year]
        case .perYear:
            components = [.year]
        }
        return components
    }
    private var chartXScale: ClosedRange<Date> {
        let calendar = Calendar.current
        switch perDate {
        case .perDay:
            let dateComp = calendar.dateComponents([.year], from: .now)
            let startDate = calendar.date(from: dateComp) ?? .now
            return startDate...Date.now
        case .perWeek:
            let startDate = calendar.date(byAdding: .year, value: -2, to: .now) ?? .now
            let endDate = calendar.date(byAdding: .weekOfMonth, value: 1, to: .now) ?? .now
            return startDate...endDate
        case .perMonth:
            let startDate = calendar.date(byAdding: .year, value: -5, to: .now) ?? .now
            let endDate = calendar.date(byAdding: .month, value: 1, to: .now) ?? .now
            return startDate...endDate
        case .perYear:
            let endDate = calendar.date(byAdding: .year, value: 1, to: .now) ?? .now
            return FTAppAssets.availableDateRange.lowerBound...endDate
        }
    }
    private var cartMatchingAlignment: DateComponents {
        switch perDate {
        case .perDay:
            return DateComponents(hour: 0)
        case .perWeek:
            return DateComponents(day: 1)
        case .perMonth:
            return DateComponents(day: 1)
        case .perYear:
            return DateComponents(month: 1)
        }
    }
    private var chartMajorAlignment: DateComponents {
        switch perDate {
        case .perDay:
            return DateComponents(day: 1)
        case .perWeek:
            return DateComponents(day: 1)
        case .perMonth:
            return DateComponents(month: 1)
        case .perYear:
            return DateComponents(month: 1)
        }
    }
    
    @State private var xScrollPosition: Date = .now
    @State private var selection: Date?
    @State private var selectionBuffer: Date?
    @State private var transactionDataSelected: [TransactionBarChartData]?
    @State private var cancleDispatchWorkItem: DispatchWorkItem?
    
    //MARK: Body
    var body: some View {
        Chart {
            ForEach(transactionsData, id: \.first?.id) { transactionArray in
                ForEach(transactionArray) { transaction in
                    BarMark(
                        x: .value("Date", transaction.date, unit: unit),
                        y: .value("Transaction", transaction.value)
                    )
                    .foregroundStyle(by: .value("Type", transaction.type.rawValue))
                    .position(by: .value("Type", transaction.type.rawValue), axis: .horizontal)
                    
                    if let selectionBuffer {
                        RuleMark(x: .value("Date", selectionBuffer, unit: unit))
                            .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                annotationPopover
                            }
                            .foregroundStyle(by: .value("Type", transaction.type.rawValue))
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            TransactionBarChartData.TransactionBarChartDataType.spending.rawValue : .red,
            TransactionBarChartData.TransactionBarChartDataType.income.rawValue : .green,
            TransactionBarChartData.TransactionBarChartDataType.profit.rawValue : .blue,
            TransactionBarChartData.TransactionBarChartDataType.unknown.rawValue : .yellow,
        ])
        .chartScrollTargetBehavior(
            .valueAligned(
                matching: cartMatchingAlignment,
                majorAlignment: .matching(chartMajorAlignment)
            )
        )
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: maxXVisibleLenth)
        .chartXScale(domain: chartXScale)
        .chartScrollPosition(x: $xScrollPosition)
        .chartXSelection(value: $selection)
        .onChange(of: selection, selectTransactionData)
        .chartXAxis {
            switch perDate {
            case .perDay:
                AxisMarks(values: .stride(by: .day)) { value in
                    if Calendar.current.component(.day, from: value.as(Date.self) ?? .now) == 1 {
                        AxisGridLine().foregroundStyle(.black)
                        AxisTick().foregroundStyle(.black)
                        AxisValueLabel(format: .dateTime.month())
                    } else {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day(.twoDigits))
                    }
                }
            case .perWeek:
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    if value.as(Date.self)!.isFirstWeekOfMonth() {
                        AxisGridLine().foregroundStyle(.black)
                        AxisTick().foregroundStyle(.black)
                        AxisValueLabel(format: .dateTime.month())
                    } else {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.week(.weekOfMonth))
                    }
                }
            case .perMonth:
                AxisMarks(values: .stride(by: .month)) { value in
                    if value.as(Date.self)!.isFirstMonthOfYear() {
                        AxisGridLine().foregroundStyle(.black)
                        AxisTick().foregroundStyle(.black)
                        AxisValueLabel(format: .dateTime.year(.twoDigits))
                    } else {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
            case .perYear:
                AxisMarks(values: .stride(by: .year)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.year(.twoDigits))
                }
            }
        }
        .chartOverlay { _ in
            if transactionsData.isEmpty {
                Label("Empty", systemImage: "xmark.app")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: perDate) {
            setSelected(nil, date: nil)
        }
        .onChange(of: transactionType) {
            setSelected(nil, date: nil)
        }
    }
    
    //MARK: Computer properties
    private var annotationPopover: some View {
        VStack(alignment: .leading) {
            if let transactionDataSelected {
                Text(getDateText(transactionDataSelected.first?.date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                ForEach(transactionDataSelected) { transaction in
                    HStack(alignment: .bottom) {
                        Text(FTFormatters.numberFormatterWithDecimals.string(for: transaction.value) ?? "0")
                            
                        Text(transaction.type.rawValue)
                            .foregroundStyle(transaction.type.color)
                    }
                    .font(.footnote)
                    .fontWeight(.medium)
                }
            }
        }
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(.secondarySystemBackground))
                .fill(Color(.systemBackground))
        }
        .padding(.top, 5)
        .background {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
        }
    }
    
    //MARK: Methods
    private func getDateText(_ date: Date?) -> String {
        guard let date else { return "" }
        let dateComponents = Calendar.current.dateComponents(componentsToCompare, from: date)
        switch perDate {
        case .perDay:
            return date.formatted(date: .abbreviated, time: .omitted)
        case .perWeek:
            return "Week \(dateComponents.weekOfMonth ?? 0), \(date.month) \(dateComponents.year ?? 0)"
        case .perMonth:
            return "\(date.month) \(dateComponents.year ?? 0)"
        case .perYear:
            return "\(dateComponents.year ?? 0)"
        }
    }
    
    private func selectTransactionData() {
        guard let selection else { return }
        let data = transactionsData.first { isBarDateEqual(left: $0.first?.date, right: selection) }
        if let data {
            setSelected(data, date: selection, withCancelation: true)
        }
    }
    
    private func isBarDateEqual(left: Date?, right: Date?) -> Bool {
        guard let left, let right else { return false }
        let calendar = Calendar.current
        return calendar.dateComponents(componentsToCompare, from: left) == calendar.dateComponents(componentsToCompare, from: right)
    }
    
    private func setSelected(_ data: [TransactionBarChartData]?, date: Date?, withCancelation: Bool = false) {
        selectionBuffer = date
        transactionDataSelected = data
        if withCancelation {
            cancelSelectionAfterDeadline()
        }
    }
    
    private func cancelSelectionAfterDeadline() {
        guard transactionDataSelected != nil else { return }
        cancleDispatchWorkItem?.cancel()
        cancleDispatchWorkItem = DispatchWorkItem {
            withAnimation {
                setSelected(nil, date: nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: cancleDispatchWorkItem!)
    }
}

#Preview {
    TransactionBarChart(transactionsData: [], perDate: .constant(.perWeek), transactionType: .constant(.both))
}
