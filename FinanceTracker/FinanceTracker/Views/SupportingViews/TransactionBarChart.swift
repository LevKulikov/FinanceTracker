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
    }
    
    let id: String = UUID().uuidString
    let type: TransactionBarChartDataType
    let value: Float
    let date: Date
}

struct TransactionBarChart: View {
    //MARK: Properties
    let transactionsData: [[TransactionBarChartData]]
    let perDate: BarChartPerDateFilter
    let transactionType: TransactionFilterTypes
    
    private var maxXVisibleLenth: Int {
        let count = transactionsData.count
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
        return seconds * (count > multiplier ? multiplier : count)
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
    @State private var xScrollPosition: Date = .now
    
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
                }
            }
        }
        .chartForegroundStyleScale([
            TransactionBarChartData.TransactionBarChartDataType.spending.rawValue : .red,
            TransactionBarChartData.TransactionBarChartDataType.income.rawValue : .green,
            TransactionBarChartData.TransactionBarChartDataType.profit.rawValue : .blue,
            TransactionBarChartData.TransactionBarChartDataType.unknown.rawValue : .yellow,
        ])
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: maxXVisibleLenth)
        .chartScrollPosition(x: $xScrollPosition)
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
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.wide))
                }
            case .perYear:
                AxisMarks(values: .stride(by: .year))
            }
        }
    }
    
    //MARK: Computer properties
    
    //MARK: Methods
    
}

#Preview {
    TransactionBarChart(transactionsData: [], perDate: .perWeek, transactionType: .both)
}
