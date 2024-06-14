//
//  TransactionPieChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI
import Charts

struct TransactionPieChart: View {
    let transactionGroups: [(category: Category, sumValue: Float)]
    private var sumOfValue: Float = 0
    
    init(transactionGroups: [(category: Category, sumValue: Float)]) {
        self.transactionGroups = transactionGroups
        sumOfValue = calculateValue()
    }
    
    var body: some View {
        VStack {
            HStack {
                Chart {
                    if !transactionGroups.isEmpty {
                        ForEach(transactionGroups, id: \.category) { singleData in
                            SectorMark(
                                angle: .value(singleData.category.name, singleData.sumValue),
                                innerRadius: .ratio(0.6)
                            )
                            .foregroundStyle(singleData.category.color)
                            .foregroundStyle(by: .value(Text(verbatim: singleData.category.name), singleData.category.name))
                        }
                    } else {
                        SectorMark(angle: .value("Empy", 100), innerRadius: .ratio(0.6))
                            .foregroundStyle(Color.gray.opacity(0.5))
                    }
                }
                .chartLegend(.hidden)
                .overlay {
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: sumOfValue) ?? "Err")
                        .foregroundStyle(.secondary)
                        .bold()
                        .frame(width: 110)
                }
                
                ScrollView {
                    VStack(alignment: .leading) {
                        if !transactionGroups.isEmpty {
                            ForEach(transactionGroups, id: \.category) {singleData in
                                HStack {
                                    BasicChartSymbolShape.circle
                                        .foregroundStyle(singleData.category.color)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(singleData.category.name)
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                        } else {
                            HStack {
                                BasicChartSymbolShape.circle
                                    .foregroundStyle(Color.gray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                
                                Text("Epty")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: FTAppAssets.getScreenSize().width / 4 * 1.3)
            }
        }
    }
    
    private func calculateValue() -> Float {
        let value = transactionGroups
            .map { $0.sumValue }
            .reduce(0, +)
        
        return value
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    @StateObject var viewModel = StatisticsViewModel(dataManager: dataManger)
    viewModel.setAnyExistingBA()
    
    return TransactionPieChart(transactionGroups: viewModel.pieChartTransactionData)
}
