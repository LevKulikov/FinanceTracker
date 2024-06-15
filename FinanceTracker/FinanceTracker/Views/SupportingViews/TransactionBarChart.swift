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
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    TransactionBarChart()
}
