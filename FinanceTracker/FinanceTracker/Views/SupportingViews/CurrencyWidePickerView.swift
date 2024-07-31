//
//  CurrencyWidePickerView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 31.07.2024.
//

import SwiftUI

struct CurrencyWidePickerView: View {
    @Binding var currency: Currency?
    @Binding var show: Bool
    
    @State private var searchCurrencyText: String = ""
    @State private var isSearching = false
    private let allCurrencies = FTAppAssets.currencies.sorted { $0.name < $1.name }
    private var searchCurrencies: [Currency] {
        guard !searchCurrencyText.isEmpty else { return allCurrencies }
        
        return allCurrencies.filter { curr in
            let nameContains = curr.name.localizedCaseInsensitiveContains(searchCurrencyText)
            let codeContains = curr.code.localizedCaseInsensitiveContains(searchCurrencyText)
            return (nameContains || codeContains)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(isSearching ? searchCurrencies : allCurrencies) { currency in
                    rowForCurrency(currency)
                }
                
                if isSearching, searchCurrencies.isEmpty {
                    ContentUnavailableView(
                        "No currencies with \"\(searchCurrencyText)\"",
                        systemImage: "magnifyingglass",
                        description: Text("Check the spelling and enter the query in English")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }
            }
            .navigationTitle("Currencies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") {
                    show = false
                }
            }
            .searchable(text: $searchCurrencyText, isPresented: $isSearching, prompt: "Currency name or code")
        }
    }
    
    @ViewBuilder
    private func rowForCurrency(_ currency: Currency) -> some View {
        HStack {
            Text(currency.name)
            Text(currency.symbol)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(currency.code)
            
            ZStack {
                Circle()
                    .stroke(.gray)
                    .fill(self.currency?.id == currency.id ? .blue : .clear)
                
                if self.currency?.id == currency.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .font(.footnote)
                }
            }
            .frame(width: 23, height: 23)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.currency = currency
        }
    }
}

#Preview {
    let someCurr = Currency(
        symbol: "$",
        name: "US Dollar",
        code: "USD"
    )
    
    @State var currency: Currency? = someCurr
    @State var show = true
    return CurrencyWidePickerView(currency: $currency, show: $show)
}
