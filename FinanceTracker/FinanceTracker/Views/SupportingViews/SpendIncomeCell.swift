//
//  SpendIncomeCell.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import SwiftUI

struct SpendIncomeCell: View {
    @Bindable var transaction: Transaction
    var namespace: Namespace.ID
    
    var body: some View {
        HStack {
            categoryImage
            
            Text(transaction.category.name)
                .font(.title3)
                .lineLimit(1)
            
            Spacer()
            
            HStack(alignment: .bottom) {
                Text(AppFormatters.numberFormatterWithDecimals.string(for: transaction.value) ?? "Err")
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "transactionValue" + transaction.id, in: namespace, isSource: false)
                
                Text(transaction.balanceAccount.currency)
                    .font(.footnote)
                    .padding(.bottom, 2.6)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "currency" + transaction.id, in: namespace, isSource: false)
            }
            .layoutPriority(1)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25.0)
                .fill(.ultraThinMaterial)
//                .matchedGeometryEffect(id: "background" + transaction.id, in: namespace, isSource: false)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var categoryImage: some View {
        let frameDimention: CGFloat = 40
        
        if let uiImage = UIImage(named: transaction.category.iconName) {
            Circle()
                .fill(LinearGradient(colors: [transaction.category.color, .clear], startPoint: .leading, endPoint: .trailing))
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .matchedGeometryEffect(id: "image" + transaction.id, in: namespace)
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
    @Namespace var namespace
    let transaction = Transaction(
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
                name: "TestCat",
                iconName: "testIcon",
                color: .cyan
            ),
        tags: []
    )
    
    return SpendIncomeCell(transaction: transaction, namespace: namespace)
}