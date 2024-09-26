//
//  SpendIncomeCell.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import SwiftUI

@MainActor
struct SpendIncomeCell: View {
    @Bindable var transaction: Transaction
    var namespace: Namespace.ID
    @State private var currency: Currency?
    
    init(transaction: Transaction, namespace: Namespace.ID, currency: Currency? = nil) {
        self.transaction = transaction
        self.namespace = namespace
        self._currency = State(wrappedValue: currency)
    }
    
    var body: some View {
        HStack {
            categoryImage
            
            Text(transaction.category?.name ?? "Err")
                .font(.title3)
                .lineLimit(1)
            
            Spacer()
            
            HStack(alignment: .bottom) {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: transaction.value) ?? "Err")
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
//                    .matchedGeometryEffect(id: "transactionValue" + transaction.id, in: namespace, isSource: false)
                
                Text(currency?.symbol ?? (transaction.balanceAccount?.currency ?? "Err"))
                    .font(.title3)
                    .lineLimit(1)
//                    .matchedGeometryEffect(id: "currency" + transaction.id, in: namespace, isSource: false)
            }
            .layoutPriority(1)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25.0)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal)
        .task {
            guard currency == nil else { return }
            if let codeString = transaction.balanceAccount?.currency {
                currency = await FTAppAssets.getCurrency(for: codeString)
            }
        }
    }
    
    @ViewBuilder
    private var categoryImage: some View {
        let frameDimention: CGFloat = 40
        
        if let category = transaction.category, let uiImage = FTAppAssets.iconUIImage(name: category.iconName) {
            Circle()
                .fill(LinearGradient(colors: [transaction.category?.color ?? .clear, .clear], startPoint: .leading, endPoint: .trailing))
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
//                        .matchedGeometryEffect(id: "image" + transaction.id, in: namespace)
                        .scaledToFit()
                        .frame(width: frameDimention - 10, height: frameDimention - 10)
                }
                .frame(width: frameDimention, height: frameDimention)
        } else {
            FTAppAssets.emptyIconImage()
                .frame(width: frameDimention, height: frameDimention)
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    let transaction = Transaction(
        type: .spending,
        comment: "",
        value: 10000.0,
        date: Date(timeIntervalSince1970: 800),
        balanceAccount:
            BalanceAccount(
                name: "TestBA",
                currency: "RUB",
                balance: 123000,
                iconName: "",
                color: .yellow
            ),
        category:
                .emptyCategory,
        tags: []
    )
    
    return SpendIncomeCell(transaction: transaction, namespace: namespace)
}
