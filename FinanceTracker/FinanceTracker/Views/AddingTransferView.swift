//
//  AddingTransferView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 14.10.2024.
//

import SwiftUI

struct AddingTransferView: View {
    //MARK: - Properties
    @StateObject private var viewModel: AddingTransferViewModel
    @FocusState private var isValueFromFieldFocused
    @FocusState private var isCurrencyRateFieldFocused
    private var navigationTitle: Text {
        switch viewModel.action {
        case .add:
            return Text("New transfer")
        case .update:
            return Text("Transfer")
        }
    }
    private var differentCurrencies: Bool {
        guard let fromBalanceAccount = viewModel.fromBalanceAccount else { return false }
        guard let toBalanceAccount = viewModel.toBalanceAccount else { return false }
        return fromBalanceAccount.currency != toBalanceAccount.currency
    }
    private var convertedValueString: String {
        FTFormatters.numberFormatterWithDecimals.string(for: viewModel.valueToConverted) ?? ""
    }
    
    //MARK: - Initializer
    init(viewModel: AddingTransferViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                valueFromField
            }
            .navigationTitle(navigationTitle)
        }
    }
    
    //MARK: - Computed View Properties
    private var valueFromField: some View {
        VStack {
            HStack {
                TextField("0", text: $viewModel.valueFromString)
                    .focused($isValueFromFieldFocused)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.valueFromString, onChangeOfValueString)
                    .font(.title)
                    .onSubmit {
                        viewModel.valueFromString = FTFormatters
                            .numberFormatterWithDecimals
                            .string(for: viewModel.valueFrom) ?? ""
                    }
                
                Text(viewModel.fromBalanceAccount?.currency ?? "")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            if true {
                Divider()
                    .padding(.top, 10)
                
                HStack {
                    TextField("0", text: $viewModel.currencyRateString)
                        .focused($isCurrencyRateFieldFocused)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.currencyRateString, onChangeOfValueString)
                        .font(.title)
                    
                    if let fromBalanceAccount = viewModel.fromBalanceAccount, let toBalanceAccount = viewModel.toBalanceAccount {
                        Button {
                            switch viewModel.currencyRateWay {
                            case .divide:
                                withAnimation {
                                    viewModel.currencyRateWay = .multiply
                                }
                            case .multiply:
                                withAnimation {
                                    viewModel.currencyRateWay = .divide
                                }
                            }
                        } label: {
                            HStack(spacing: 0) {
                                Text(toBalanceAccount.currency)
                                Text("/")
                                Text(fromBalanceAccount.currency)
                            }
                            .font(.title3)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("= " + convertedValueString)
                        .font(.title)
                    
                    Text(viewModel.toBalanceAccount?.currency ?? "")
                        .font(.title2)
                    
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(.ultraThinMaterial)
                .onTapGesture {
                    isValueFromFieldFocused = true
                }
        }
        .padding(.horizontal, 10)
    }
    
    //MARK: - Methods
    private func onChangeOfValueString() {
        var copyString = viewModel.valueFromString
        guard !copyString.isEmpty else {
            if viewModel.valueFrom != 0 {
                viewModel.valueFrom = 0
            }
            return
        }
        
        // replace comma with dot
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        // remove spaces
        if copyString.contains(" ") {
            copyString.replace(" ", with: "")
        }
        
        guard let floatValue = Float(copyString) else {
            viewModel.valueFromString = ""
            viewModel.valueFrom = 0
            return
        }
        
        viewModel.valueFrom = floatValue
        
        if copyString.count > 1 {
            let firstTwoChars = copyString.prefix(2)
            if firstTwoChars == "0." || firstTwoChars == "0," {
                return
            } else if firstTwoChars.first == "0" {
                viewModel.valueFromString.removeFirst()
            }
        }
    }
    
    private func onChangeOfCurrencyRateString() {
        var copyString = viewModel.currencyRateString
        guard !copyString.isEmpty else {
            if viewModel.currencyRateValue != 0 {
                viewModel.currencyRateValue = 0
            }
            return
        }
        
        // replace comma with dot
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        // remove spaces
        if copyString.contains(" ") {
            copyString.replace(" ", with: "")
        }
        
        guard let floatValue = Float(copyString) else {
            viewModel.currencyRateString = ""
            viewModel.currencyRateValue = 0
            return
        }
        
        viewModel.currencyRateValue = floatValue
        
        if copyString.count > 1 {
            let firstTwoChars = copyString.prefix(2)
            if firstTwoChars == "0." || firstTwoChars == "0," {
                return
            } else if firstTwoChars.first == "0" {
                viewModel.currencyRateString.removeFirst()
            }
        }
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AddingTransferViewModel(dataManager: dataManager, action: .add(template: nil))
    
    AddingTransferView(viewModel: viewModel)
}
