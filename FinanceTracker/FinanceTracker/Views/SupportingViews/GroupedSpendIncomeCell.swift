//
//  GroupedSpendIncomeCell.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 03.06.2024.
//

import SwiftUI

struct GroupedSpendIncomeCell: View {
    var transactions: [Transaction]
    var namespace: Namespace.ID
    @Binding var closeGroupFlag: Bool
    var onTapTransaction: (Transaction) -> Void
    
    @State private var openGroup = false
    private var mutualCategory: Category? {
        return transactions.first?.category
    }
    private var mutualBalanceAccount: BalanceAccount? {
        return transactions.first?.balanceAccount
    }
    private var transactionsValueSum: Float {
        transactions.map { $0.value }.reduce(0, +)
    }
    
    var body: some View {
        VStack {
            if !openGroup {
                groupCellPreview
                    .transition(.blurReplace)
                    .onTapGesture {
                        closeGroupFlag = false
                        withAnimation {
                            openGroup = true
                        }
                    }
            } else {
                groupCellOpenedView
                    .transition(.blurReplace.combined(with: .push(from: .bottom)))
            }
            
            if openGroup {
                ForEach(transactions) { transaction in
                    SpendIncomeCell(transaction: transaction, namespace: namespace)
                        .transition(.blurReplace)
                        .onTapGesture {
                            onTapTransaction(transaction)
                        }
                }
            }
        }
        .padding(.bottom, openGroup ? 20 : 0)
        .onChange(of: closeGroupFlag) {
            if closeGroupFlag {
                withAnimation(.snappy(duration: 0.5)) {
                    openGroup = false
                }
            }
        }
    }
    
    private var groupCellPreview: some View {
        HStack {
            categoryImage
            
            Text(mutualCategory?.name ?? "Error")
                .font(.title3)
                .lineLimit(1)
            
            Spacer()
            
            HStack(alignment: .bottom) {
                Text(AppFormatters.numberFormatterWithDecimals.string(for: transactionsValueSum) ?? "Err")
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                
                Text(mutualBalanceAccount?.currency ?? "Err")
                    .font(.footnote)
                    .padding(.bottom, 2.6)
                    .lineLimit(1)
                
                Text("(\(transactions.count))")
                    .font(.footnote)
                    .padding(.bottom, 2.6)
            }
            .layoutPriority(1)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25.0)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal)
    }
    
    private var groupCellOpenedView: some View {
        HStack {
            Text(mutualCategory?.name ?? "Error")
                .font(.title2)
                .bold()
                .lineLimit(1)
            
            Spacer()
            
            Button("Show less", systemImage: "chevron.up") {
                withAnimation {
                    openGroup = false
                }
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var categoryImage: some View {
        let frameDimention: CGFloat = 40
        
        if let mutualCategory, let uiImage = UIImage(named: mutualCategory.iconName) {
            Circle()
                .fill(LinearGradient(colors: [mutualCategory.color, .clear], startPoint: .leading, endPoint: .trailing))
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameDimention - 10, height: frameDimention - 10)
                }
                .frame(width: frameDimention, height: frameDimention)
        } else {
            Image(systemName: "circle")
                .resizable()
                .scaledToFit()
                .overlay {
                    Image(systemName: "xmark")
                        .font(.title)
                        .bold()
                }
                .frame(width: frameDimention, height: frameDimention)
        }
    }
}

#Preview {
//    let container = FinanceTrackerApp.createModelContainer()
//    let dataManager = DataManager(container: container)
//    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
//    viewModel.fetchTransactions()
    
    @Namespace var namespace
    @State var flag = false
    
    let transactions = [
        Transaction(
            type: .spending,
            comment: "",
            value: 1000,
            date: .now,
            balanceAccount:
                BalanceAccount(
                    name: "TestBA",
                    currency: "RUB",
                    balance: 123000,
                    iconName: "",
                    color: .yellow
                ),
            category:
                Category(
                    type: .spending,
                    name: "Test categ",
                    iconName: "testIcon",
                    color: .cyan
                ),
            tags: []
        ),
        Transaction(
            type: .spending,
            comment: "",
            value: 1000,
            date: .now,
            balanceAccount:
                BalanceAccount(
                    name: "Test categ",
                    currency: "RUB",
                    balance: 123000,
                    iconName: "",
                    color: .yellow
                ),
            category:
                Category(
                    type: .spending,
                    name: "Test categ",
                    iconName: "testIcon",
                    color: .cyan
                ),
            tags: []
        ),
        Transaction(
            type: .spending,
            comment: "",
            value: 1000,
            date: .now,
            balanceAccount:
                BalanceAccount(
                    name: "TestBA",
                    currency: "RUB",
                    balance: 123000,
                    iconName: "",
                    color: .yellow
                ),
            category:
                Category(
                    type: .spending,
                    name: "Test categ",
                    iconName: "testIcon",
                    color: .cyan
                ),
            tags: []
        ),
        Transaction(
            type: .spending,
            comment: "",
            value: 1000,
            date: .now,
            balanceAccount:
                BalanceAccount(
                    name: "TestBA",
                    currency: "RUB",
                    balance: 123000,
                    iconName: "",
                    color: .yellow
                ),
            category:
                Category(
                    type: .spending,
                    name: "Test categ",
                    iconName: "testIcon",
                    color: .cyan
                ),
            tags: []
        ),
        Transaction(
            type: .spending,
            comment: "",
            value: 1000,
            date: .now,
            balanceAccount:
                BalanceAccount(
                    name: "TestBA",
                    currency: "RUB",
                    balance: 123000,
                    iconName: "",
                    color: .yellow
                ),
            category:
                Category(
                    type: .spending,
                    name: "Test categ",
                    iconName: "testIcon",
                    color: .cyan
                ),
            tags: []
        )
    ]
    
    return GroupedSpendIncomeCell(transactions: transactions, namespace: namespace, closeGroupFlag: $flag) {
        print($0.typeRawValue)
    }
}
