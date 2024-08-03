//
//  SearchSection.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 28.06.2024.
//

import SwiftUI

struct SearchSection: View, @unchecked Sendable {
    //MARK: Props
    let transactionGroupData: TransactionGroupedData
    let onTapAction: @MainActor @Sendable (Transaction) -> Void
    let onDeleteSwipe: @MainActor @Sendable (Transaction) -> Void
    
    private let calendar = Calendar.current
    @State private var haveSameCurrency: Bool = true
    @State private var totalSpending: Float?
    @State private var totalIncome: Float?
    
    //MARK: Init
    init(transactionGroupData: TransactionGroupedData, onTapAction: @MainActor @Sendable @escaping (Transaction) -> Void, onDeleteSwipe: @MainActor @Sendable @escaping (Transaction) -> Void) {
        self.transactionGroupData = transactionGroupData
        self.onTapAction = onTapAction
        self.onDeleteSwipe = onDeleteSwipe
    }
    
    //MARK: Body
    var body: some View {
        Section {
            ForEach(transactionGroupData.transactions.reversed()) { transaction in
                SearchTransactionRow(transaction: transaction)
                    .onTapGesture {
                        onTapAction(transaction)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            onDeleteSwipe(transaction)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
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
                Text("\(TransactionsType.income.localizedString): \(FTFormatters.numberFormatterWithDecimals.string(for: totalIncome) ?? "0")")
            }
            
            Spacer()
            
            if let totalSpending {
                Text("\(TransactionsType.spending.localizedString): \(FTFormatters.numberFormatterWithDecimals.string(for: totalSpending) ?? "0")")
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
        Task(priority: .high) {
            let incomeTransactions = transactionGroupData.transactions.filter { $0.type == .income }
            guard !incomeTransactions.isEmpty else { return }
            let sumValue = incomeTransactions.map { $0.value }.reduce(0, +)
            
            await MainActor.run {
                totalIncome = sumValue
            }
        }
    }
    
    private func calculateTotalSpending() {
        guard haveSameCurrency else { return }
        Task(priority: .high) {
            let spendingTransactions = transactionGroupData.transactions.filter { $0.type == .spending }
            guard !spendingTransactions.isEmpty else { return }
            let sumValue = spendingTransactions.map { $0.value }.reduce(0, +)
            
            await MainActor.run {
                totalSpending = sumValue
            }
        }
    }
}

#Preview {
    SearchSection(transactionGroupData: TransactionGroupedData(date: .now, transactions: [])) { trans in
        print(trans.value)
    } onDeleteSwipe: { _ in
        
    }
}
