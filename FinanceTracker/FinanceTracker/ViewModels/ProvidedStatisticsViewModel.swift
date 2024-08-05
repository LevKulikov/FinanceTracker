//
//  ProvidedStatisticsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 03.08.2024.
//

import Foundation
import SwiftUI

struct TotalValueData: Identifiable {
    let id = UUID().uuidString
    let type: TransactionCalculationValueType
    var value: Float
}

/// ViewModel for View, thats represents statistics for provided transactions and other data. This view model does not fetch any data by itself
final class ProvidedStatisticsViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    
    
    //MARK: Published properties
    @MainActor @Published private(set) var providedTransactionType: TransactionFilterTypes = .both
    
    /// Array of total values. Its is array because of there can be different transaction types so it is needed to get total values for spendings, income and profit
    @MainActor @Published private(set) var totalValues: [TotalValueData] = []
    
    @MainActor @Published private(set) var pieChartTransactionData: [TransactionPieChartData] = []
    @MainActor @Published private(set) var pieDataIsCalculating = false
    @MainActor @Published var pieChartTransactionType: TransactionsType = .spending {
        didSet {
            guard pieChartTransactionType != oldValue else { return }
            Task {
                await calculateDataForPieChart(animated: true)
            }
        }
    }
    
    @MainActor @Published private(set) var barChartTransactionData: [[TransactionBarChartData]] = []
    @MainActor @Published private(set) var barDataIsCalculating = false
    @MainActor @Published var barChartTransactionTypeFilter: TransactionFilterTypes = .spending {
        didSet {
            guard barChartTransactionTypeFilter != oldValue else { return }
            Task {
                await calculateDataForBarChart(animated: true)
            }
        }
    }
    @MainActor @Published var barChartPerDateFilter: BarChartPerDateFilter = .perDay {
        didSet {
            guard barChartPerDateFilter != oldValue else { return }
            Task {
                await calculateDataForBarChart(animated: true)
            }
        }
    }
    
    //MARK: Private properties
    /// Transactions to calculate statistics for
    private let transactions: [Transaction]
    ///Currency code String
    let currency: String
    /// Currency struct with code, name, symbol and etc.
    let currencyPrecised: Currency?
    private let calendar = Calendar.current
    
    //MARK: - Initializer
    init(transactions: [Transaction], currency: String) {
        self.transactions = transactions
        self.currency = currency
        self.currencyPrecised = nil
        calculateAllData()
    }
    
    init(transactions: [Transaction], currency: Currency) {
        self.transactions = transactions
        self.currency = currency.code
        self.currencyPrecised = currency
        calculateAllData()
    }
    
    //MARK: - Methods
    
    
    //MARK: Private methods
    private func calculateAllData() {
        Task(priority: .medium) {
            await checkTransactionsType()
            
            await withTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTask {
                    await self.calculateTotalValues()
                }
                
                taskGroup.addTask {
                    await self.calculateDataForPieChart(animated: true)
                }
                
                taskGroup.addTask {
                    await self.calculateDataForBarChart()
                }
            }
        }
    }
    
    /// Checkes if provided transactions have same  type or they are different
    private func checkTransactionsType() async {
        guard let firstTransactionType = transactions.first?.type else {
            await MainActor.run {
                providedTransactionType = .spending
            }
            return
        }
        
        for transaction in transactions {
            if transaction.type != firstTransactionType {
                await MainActor.run { providedTransactionType = .both }
                return
            }
        }
        
        await MainActor.run {
            switch firstTransactionType {
            case .spending:
                providedTransactionType = .spending
            case .income:
                providedTransactionType = .income
            }
        }
    }
    
    /// Calculates total values
    private func calculateTotalValues() async {
        guard !transactions.isEmpty else { return }
        let typeProvidedCopy = await MainActor.run { return providedTransactionType }
        
        switch typeProvidedCopy {
        case .income, .spending:
            let totalValue = transactions.map { $0.value }.reduce(0, +)
            let totalData = TotalValueData(type: typeProvidedCopy == .income ? .income : .spending, value: totalValue)
            await MainActor.run {
                totalValues = [totalData]
            }
            
        case .both:
            var spendingData = TotalValueData(type: .spending, value: 0)
            var incomeData = TotalValueData(type: .income, value: 0)
            
            for transaction in transactions {
                guard let transactionType = transaction.type else {
                    continue
                }
                
                switch transactionType {
                case .spending:
                    spendingData.value += transaction.value
                case .income:
                    incomeData.value += transaction.value
                }
            }
            
            let profitData = TotalValueData(type: .profit, value: incomeData.value - spendingData.value)
            
            await MainActor.run { [incomeData, spendingData] in
                totalValues = [incomeData, spendingData, profitData]
            }
        }
    }
    
    /// Calculates data for pie chart and sets it with animation
    private func calculateDataForPieChart(animated: Bool = false) async {
        guard !transactions.isEmpty else { return }
        
        await MainActor.run {
            pieDataIsCalculating = true
        }
        
        var filteredTransactions: [Transaction] = transactions
        
        let typeProvidedCopy = await MainActor.run { return providedTransactionType }
        if typeProvidedCopy == .both {
            let typeCopy = await MainActor.run { return pieChartTransactionType }
            filteredTransactions = filteredTransactions.filter { $0.type == typeCopy }
        }
        
        let groupedData = filteredTransactions
            .grouped { $0.category }
            .map { singleDict in
                let totalValueForCategory = singleDict.value.map{ $0.value }.reduce(0, +)
                let transactions = singleDict.value
                return TransactionPieChartData(category: singleDict.key ?? .emptyCategory, sumValue: totalValueForCategory, transactions: transactions)
            }
        
        let sortedData = groupedData.sorted(by: { $0.sumValue > $1.sumValue })
        
        do {
            try await Task.sleep(for: .seconds(0.1))
        } catch {
            print("Task.sleep(for: .seconds(0.1)) error: \(error)")
        }
        
        await MainActor.run {
            pieDataIsCalculating = false
            if animated {
                withAnimation {
                    pieChartTransactionData = sortedData
                }
            } else {
                pieChartTransactionData = sortedData
            }
        }
    }
    
    /// Calculates data for bar chart and sets it with animation
    private func calculateDataForBarChart(animated: Bool = false) async {
        await MainActor.run {
            barDataIsCalculating = true
        }
        
        var filteredTransactions: [Transaction] = transactions
        
        let typeProvidedCopy = await MainActor.run { return providedTransactionType }
        if typeProvidedCopy == .both {
            let typeCopy = await MainActor.run { return barChartTransactionTypeFilter }
            filteredTransactions = filteredTransactions
                .filter { singleTransaction in
                    switch typeCopy {
                    case .both:
                        return true
                    case .spending:
                        return (singleTransaction.type == .spending)
                    case .income:
                        return (singleTransaction.type == .income)
                    }
                }
        }
        
        let barChartPerDateFilterCopy = await MainActor.run { return barChartPerDateFilter }
        let timeGroupedData = filteredTransactions
            .grouped { singleTransaction in
                let year = calendar.component(.year, from: singleTransaction.date)
                let month = calendar.component(.month, from: singleTransaction.date)
                
                switch barChartPerDateFilterCopy {
                case .perDay:
                    let day = calendar.component(.day, from: singleTransaction.date)
                    return DateComponents(year: year, month: month, day: day)
                case .perWeek:
                    let dateComp = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: singleTransaction.date)
                    return dateComp
                case .perMonth:
                    return DateComponents(year: year, month: month)
                case .perYear:
                    return DateComponents(year: year)
                }
            }
        
        let barChartTransactionTypeFilterCopy = await MainActor.run { return barChartTransactionTypeFilter }
        let barData = timeGroupedData
            .map { singleGroup in
                let dateToSet = calendar.date(from: singleGroup.key) ?? .now
                let groupedByTransTypeDict = singleGroup.value.grouped { $0.type }
                
                var arrayOfBarData =  groupedByTransTypeDict.map {
                    let sumValue = $0.value.map { $0.value }.reduce(0, +)
                    
                    switch $0.key {
                    case .spending:
                        return TransactionBarChartData(type: .spending, value: sumValue, date: dateToSet)
                    case .income:
                        return TransactionBarChartData(type: .income, value: sumValue, date: dateToSet)
                    case .none:
                        return TransactionBarChartData(type: .unknown, value: sumValue, date: dateToSet)
                    }
                }
                
                if barChartTransactionTypeFilterCopy == .both {
                    var incomeTransData = arrayOfBarData.first { $0.type == .income }
                    if incomeTransData == nil {
                        incomeTransData = TransactionBarChartData(type: .income, value: 0, date: dateToSet)
                        arrayOfBarData.append(incomeTransData!)
                    }
                    
                    var spendTransData = arrayOfBarData.first { $0.type == .spending }
                    if spendTransData == nil {
                        spendTransData = TransactionBarChartData(type: .spending, value: 0, date: dateToSet)
                        arrayOfBarData.append(spendTransData!)
                    }
                    
                    let profitValue = incomeTransData!.value - spendTransData!.value
                    let profitData = TransactionBarChartData(type: .profit, value: profitValue, date: dateToSet)
                    arrayOfBarData.append(profitData)
                }
                
                return arrayOfBarData
            }
        
        await MainActor.run {
            barDataIsCalculating = false
            if animated {
                withAnimation {
                    barChartTransactionData = barData
                }
            } else {
                barChartTransactionData = barData
            }
        }
    }
}
