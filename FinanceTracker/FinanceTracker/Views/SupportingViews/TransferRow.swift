//
//  TransferRow.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 21.10.2024.
//

import SwiftUI

struct TransferRow: View {
    let transfer: TransferTransaction
    @State private var currencyFrom: Currency?
    @State private var currencyTo: Currency?
    private var differentCurrecny: Bool {
        transfer.fromBalanceAccount?.currency != transfer.toBalanceAccount?.currency
    }
    
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transfer.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                balanceAccountView
            }
            
            Spacer()
            
            valueView
                .layoutPriority(1)
        }
        .contentShape(Rectangle())
        .task {
            if let codeStringTo = transfer.toBalanceAccount?.currency {
                async let currencyTo = FTAppAssets.getCurrency(for: codeStringTo)
                
                if differentCurrecny, let codeStringFrom = transfer.fromBalanceAccount?.currency {
                    async let currencyFrom = FTAppAssets.getCurrency(for: codeStringFrom)
                    
                    self.currencyTo = await currencyTo
                    self.currencyFrom = await currencyFrom
                } else {
                    self.currencyTo = await currencyTo
                    self.currencyFrom = self.currencyTo
                }
            }
        }
    }
    
    private var valueView: some View {
        VStack(alignment: .trailing) {
            if differentCurrecny {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.turn.left.down")
                    
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: transfer.valueFrom) ?? "Err")
                    
                    Text(currencyFrom?.symbol ?? (transfer.fromBalanceAccount?.currency ?? "Err"))
                }
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            
            HStack(spacing: 4) {
                Text(FTFormatters.numberFormatterWithDecimals.string(for: transfer.valueTo) ?? "Err")
                    .bold()
                
                Text(currencyTo?.symbol ?? (transfer.toBalanceAccount?.currency ?? "Err"))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
    }
    
    private var balanceAccountView: some View {
        HStack(spacing: 2) {
            getImage(name: transfer.fromBalanceAccount?.iconName)
                .foregroundStyle(transfer.fromBalanceAccount?.color ?? .primary)
            
            Text(transfer.fromBalanceAccount?.name ?? "Err")
            
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            
            getImage(name: transfer.toBalanceAccount?.iconName)
                .foregroundStyle(transfer.toBalanceAccount?.color ?? .secondary)
            
            Text(transfer.toBalanceAccount?.name ?? "Err")
        }
        .font(.footnote)
        .lineLimit(1)
    }
    
    @ViewBuilder
    private func getImage(name: String?) -> some View {
        let frameDimensions: CGFloat = 15
        
        if let name, let uiImage = FTAppAssets.iconUIImage(name: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: frameDimensions, height: frameDimensions)
        } else {
            FTAppAssets.emptyIconImage()
                .frame(width: frameDimensions, height: frameDimensions)
        }
    }
}

#Preview {
    let transaction = TransferTransaction(valueFrom: 1000, valueTo: 10000, date: .now, comment: "", fromBalanceAccount: .emptyBalanceAccount, toBalanceAccount: .emptyBalanceAccount)
    TransferRow(transfer: transaction)
}
