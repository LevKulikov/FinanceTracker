//
//  AddingTransferView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 14.10.2024.
//

import SwiftUI

struct AddingTransferView: View {
    //MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @Namespace private var namespace
    @StateObject private var viewModel: AddingTransferViewModel
    @FocusState private var isValueFromFieldFocused
    @FocusState private var isCurrencyRateFieldFocused
    @FocusState private var commentTextFieldFocus
    @State private var saveError: AddingTransferViewModel.SaveTransferTransactionError?
    @State private var rotateSwitchArrow = false
    private var navigationTitle: Text {
        switch viewModel.action {
        case .add:
            return Text("New transfer")
        case .update:
            return Text("Transfer")
        }
    }
    private var buttonTitleAndIcon: (String, String) {
        switch viewModel.action {
        case .add:
            return (String(localized: "Transfer"), "arrow.right.arrow.left")
        case .update:
            return (String(localized: "Update"), "pencil.and.outline")
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
                    .padding(.bottom)
                
                balanceAccountsSelectionView
                    .padding(.bottom)
                
                dateSectionView
                    .padding(.bottom)
                
                commentSection
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 50)
            }
            .navigationTitle(navigationTitle)
            .background {
                Rectangle()
                    .fill(.background)
                    .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                if !commentTextFieldFocus {
                    addUpdateButton
                }
            }
            .onTapGesture(perform: dismissKeyboardFocus)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button("", systemImage: "keyboard.chevron.compact.down.fill", action: dismissKeyboardFocus)
                        .labelsHidden()
                }
            }
            .alert(Text(saveError?.saveErrorLocalizedDescription ?? "Error"),
                   isPresented: .init(get: { saveError != nil }, set: { _ in saveError = nil })) {
                Button("Ok") {}
            }
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
            .onTapGesture {
                isValueFromFieldFocused = true
            }
            
            if differentCurrencies {
                Divider()
                    .padding(.top, 10)
                
                HStack {
                    TextField("0", text: $viewModel.currencyRateString)
                        .focused($isCurrencyRateFieldFocused)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.currencyRateString, onChangeOfCurrencyRateString)
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
                                switch viewModel.currencyRateWay {
                                case .divide:
                                    Text(toBalanceAccount.currency)
                                        .matchedGeometryEffect(id: "leftCurrency", in: namespace)
                                    Text("/")
                                    Text(fromBalanceAccount.currency)
                                        .matchedGeometryEffect(id: "rightCurrency", in: namespace)
                                case .multiply:
                                    Text(fromBalanceAccount.currency)
                                        .matchedGeometryEffect(id: "rightCurrency", in: namespace)
                                    Text("/")
                                    Text(toBalanceAccount.currency)
                                        .matchedGeometryEffect(id: "leftCurrency", in: namespace)
                                }
                            }
                            .font(.title3)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("= " + convertedValueString)
                        .font(.title)
                        .lineLimit(1)
                    
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
        }
        .padding(.horizontal, 10)
    }
    
    private var balanceAccountsSelectionView: some View {
        HStack {
            VStack {
                Text("From")
                    .bold()
                
                Menu(viewModel.fromBalanceAccount?.name ?? String(localized: "Empty")) {
                    Picker("From Balance Accounts", selection: $viewModel.fromBalanceAccount) {
                        ForEach(viewModel.balanceAccounts) { balanceAcc in
                            HStack {
                                Text(balanceAcc.name)
                                
                                if let uiImage = FTAppAssets.iconUIImage(name: balanceAcc.iconName) {
                                    Image(uiImage: uiImage)
                                } else {
                                    Image(systemName: "xmark")
                                }
                            }
                            .tag(Optional(balanceAcc))
                        }
                    }
                }
                .buttonStyle(.bordered)
                .lineLimit(1)
                .foregroundStyle(.primary)
                .hoverEffect(.highlight)
            }
            .frame(width: 110)
            
            Image(systemName: "arrowshape.right")
                .font(.system(size: 45))
                .padding(.horizontal)
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(rotateSwitchArrow ? 360 : 0))
                .onTapGesture {
                    withAnimation {
                        rotateSwitchArrow.toggle()
                        viewModel.switchBalanceAccounts()
                    }
                }
            
            VStack {
                Text("To")
                    .bold()
                
                Menu(viewModel.toBalanceAccount?.name ?? String(localized: "Empty")) {
                    Picker("To Balance Accounts", selection: $viewModel.toBalanceAccount) {
                        ForEach(viewModel.balanceAccounts) { balanceAcc in
                            HStack {
                                Text(balanceAcc.name)
                                
                                if let uiImage = FTAppAssets.iconUIImage(name: balanceAcc.iconName) {
                                    Image(uiImage: uiImage)
                                } else {
                                    Image(systemName: "xmark")
                                }
                            }
                            .tag(Optional(balanceAcc))
                        }
                    }
                }
                .buttonStyle(.bordered)
                .lineLimit(1)
                .foregroundStyle(.primary)
                .hoverEffect(.highlight)
            }
            .frame(width: 110)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 10)
    }
    
    private var dateSectionView: some View {
        VStack(alignment: .leading) {
            Text("Date")
                .font(.title2)
                .fontWeight(.medium)
            
            HStack {
                Picker("", selection: $viewModel.date) {
                    ForEach(viewModel.threeDatesArray, id: \.self) { dateToSet in
                        Text("\(dateToSet.get(.day)) \(dateToSet.month.prefix(3)).")
                            .tag(dateToSet)
                    }
                }
                .pickerStyle(.segmented)
                .scaleEffect(y: 1.1)
                
                Spacer()
                
                DatePicker("", selection: $viewModel.date, in: viewModel.availableDateRange, displayedComponents: .date)
                    .labelsHidden()
            }
            .onTapGesture(count: 20) {
                // overrides tap gesture to fix ios 17.1 bug
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 10)
    }
    
    private var commentSection: some View {
        VStack(alignment: .leading) {
            Text("Comment")
                .font(.title2)
                .fontWeight(.medium)
            
            TextField("Comment", text: $viewModel.comment, prompt: Text("Enter comment"), axis: .vertical)
                .lineLimit(3...5)
                .focused($commentTextFieldFocus)
                .padding(10)
                .background(.gray.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 10)
    }
    
    private var addUpdateButton: some View {
        Button {
            viewModel.saveTransferTransaction { result in
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    saveError = error
                }
            }
        } label: {
            Label(buttonTitleAndIcon.0, systemImage: buttonTitleAndIcon.1)
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(.blue)
                }
        }
        .offset(y: -5)
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
    
    private func dismissKeyboardFocus() {
        isValueFromFieldFocused = false
        isCurrencyRateFieldFocused = false
        commentTextFieldFocus = false
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AddingTransferViewModel(dataManager: dataManager, action: .add(template: nil))
    
    AddingTransferView(viewModel: viewModel)
}
