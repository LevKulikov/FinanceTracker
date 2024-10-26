//
//  TransferRow.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 21.10.2024.
//

import SwiftUI

struct TransferRow: View {
    let transfer: TransferTransaction
    let showDate: Bool
    @State private var currencyFrom: Currency?
    @State private var currencyTo: Currency?
    private var differentCurrecny: Bool {
        transfer.fromBalanceAccount?.currency != transfer.toBalanceAccount?.currency
    }
    
    init(transfer: TransferTransaction, showDate: Bool = true) {
        self.transfer = transfer
        self.showDate = showDate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if showDate {
                Text(transfer.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                balanceAccountView
                
                Spacer()
                
                valueView
                    .layoutPriority(1)
            }
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
        HStack(spacing: 0) {
            Image(systemName: "arrow.uturn.up")
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(90))
                .font(.title3)
                .offset(y: 4)
                
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 2) {
                    getImage(name: transfer.fromBalanceAccount?.iconName)
                        .foregroundStyle(transfer.fromBalanceAccount?.color ?? .primary)
                    
                    Text(transfer.fromBalanceAccount?.name ?? "Err")
                }
                
                HStack(spacing: 2) {
                    getImage(name: transfer.toBalanceAccount?.iconName)
                        .foregroundStyle(transfer.toBalanceAccount?.color ?? .secondary)
                    
                    Text(transfer.toBalanceAccount?.name ?? "Err")
                }
            }
            .font(.footnote)
            .lineLimit(2)
        }
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
