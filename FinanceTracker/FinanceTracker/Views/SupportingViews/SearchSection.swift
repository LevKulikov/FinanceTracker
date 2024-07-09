//
//  SearchSection.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 28.06.2024.
//

import SwiftUI

struct SearchSection: View {
    //MARK: Props
    let transactionGroupData: TransactionGroupedData
    let onTapAction: (Transaction) -> Void
    
    private let calendar = Calendar.current
    @State private var haveSameCurrency: Bool = true
    @State private var totalSpending: Float?
    @State private var totalIncome: Float?
    
    //MARK: Init
    init(transactionGroupData: TransactionGroupedData, onTapAction: @escaping (Transaction) -> Void) {
        self.transactionGroupData = transactionGroupData
        self.onTapAction = onTapAction
    }
    
    //MARK: Body
    var body: some View {
        Section {
            ForEach(transactionGroupData.transactions.reversed()) { transaction in
                SearchTransactionRow(transaction: transaction)
                    .onTapGesture {
                        onTapAction(transaction)
                    }
            }
        } header: {
            headerView
        } footer: {
            footerView
        }
        .onAppear {
            checkTransactionsCurrency()
            calculateTotalSpending()
            calculateTotalIncome()
        }
    }
    
    private var headerView: some View {
        Text(getDateString(transactionGroupData.date))
    }
    
    private var footerView: some View {
        HStack {
            if let totalIncome {
                Text("\(TransactionsType.income.rawValue): \(FTFormatters.numberFormatterWithDecimals.string(for: totalIncome) ?? "0")")
            }
            
            Spacer()
            
            if let totalSpending {
                Text("\(TransactionsType.spending.rawValue): \(FTFormatters.numberFormatterWithDecimals.string(for: totalSpending) ?? "0")")
            }
        }
    }
    
    //MARK: Methods
    private func getDateString(_ date: Date) -> String {
        let weekday = FTFormatters.dayOfWeek(for: date) ?? ""
        let day = calendar.component(.day, from: date)
        let month = date.month
        let year = calendar.component(.year, from: date)
        return "\(weekday), \(day) \(month) \(year)"
    }
    
    private func checkTransactionsCurrency() {
        let transactions = transactionGroupData.transactions
        guard let first = transactions.first else { return }
        let checkCurrency = first.balanceAccount?.currency
        let ifOtherExists = transactions.contains { trans in
            guard let balanceAccount = trans.balanceAccount else { return false }
            return balanceAccount.currency != checkCurrency
        }
        haveSameCurrency = !ifOtherExists
    }
    
    private func calculateTotalIncome() {
        guard haveSameCurrency else { return }
        DispatchQueue.global().async {
            let incomeTransactions = transactionGroupData.transactions.filter { $0.type == .income }
            guard !incomeTransactions.isEmpty else { return }
            let sumValue = incomeTransactions.map { $0.value }.reduce(0, +)
            
            DispatchQueue.main.async {
                totalIncome = sumValue
            }
        }
    }
    
    private func calculateTotalSpending() {
        guard haveSameCurrency else { return }
        DispatchQueue.global().async {
            let spendingTransactions = transactionGroupData.transactions.filter { $0.type == .spending }
            guard !spendingTransactions.isEmpty else { return }
            let sumValue = spendingTransactions.map { $0.value }.reduce(0, +)
            
            DispatchQueue.main.async {
                totalSpending = sumValue
            }
        }
    }
}

#Preview {
    SearchSection(transactionGroupData: TransactionGroupedData(date: .now, transactions: [])) { trans in
        print(trans.value)
    }
}
