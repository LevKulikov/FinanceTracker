//
//  AddingBalanceAccauntView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 10.06.2024.
//

import SwiftUI

struct AddingBalanceAccauntView: View {
    //MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddingBalanceAccountViewModel
    @FocusState private var nameTextFieldFocus
    @FocusState private var balanceTextFieldFocus
    @FocusState private var currencyTextFieldFocus
    @State private var showMoreIcons = false
    private let userDevice = FTAppAssets.currentUserDevise
    private var canBeAddedOrUpdated: Bool {
        guard !viewModel.name.isEmpty else { return false }
        guard !viewModel.currency.isEmpty else { return false }
        guard !viewModel.iconName.isEmpty else { return false }
        return true
    }
    private var isKeyboardActive: Bool {
        nameTextFieldFocus || balanceTextFieldFocus || currencyTextFieldFocus
    }
    
    private var isAdding: Bool {
        viewModel.action == .add
    }
    
    //MARK: - Initializer
    init(viewModel: AddingBalanceAccountViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        ScrollView {
            VStack {
//                headerView
//                    .padding(.vertical, 10)
                
                nameSection
                
                Divider()
                    .padding(.horizontal)
                    .padding(.bottom)
                
                balanceSection
                
                Divider()
                    .padding(.horizontal)
                    .padding(.bottom)
                
                iconSelectionSection
                
                Divider()
                    .padding(.horizontal)
                    .padding(.bottom)
                
                colorPickerSection
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 50)
            }
        }
        .navigationTitle(isAdding ? "New balance account" : "Balance account")
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture {
            dismissKeyboard()
        }
        .sheet(isPresented: $showMoreIcons) {
            iconsListView
        }
        .overlay(alignment: .bottom) {
            if !isKeyboardActive {
                addButton
                    .offset(y: userDevice == .phone ? 0 : -60)
            }
        }
    }
    
    //MARK: View Properties
    private var headerView: some View {
        HStack {
            Text(isAdding ? "New balance account" : "Balance account")
                .font(.title)
                .bold()
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.title2)
                .fontWeight(.medium)
            
            TextField("Balance account name", text: $viewModel.name, prompt: Text("Enter name here"))
                .focused($nameTextFieldFocus)
                .font(.title2)
        }
        .padding(.horizontal)
    }
    
    private var balanceSection: some View {
        VStack(alignment: .leading) {
            Text((isAdding ? "Initial balance" : "Current balance") + " and currency")
                .font(.title2)
                .fontWeight(.medium)
            
            HStack {
                TextField(viewModel.isFetching ? "Please wait" : "0", text: $viewModel.balanceString)
                    .onChange(of: viewModel.balanceString, onChangeOfBalanceString)
                    .focused($balanceTextFieldFocus)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .font(.title2)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isFetching)
                    .overlay(alignment: .trailing) {
                        if viewModel.isFetching {
                            ProgressView().padding(.trailing)
                        }
                    }
                
                TextField("USD", text: $viewModel.currency)
                    .focused($currencyTextFieldFocus)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.title2)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: FTAppAssets.getScreenSize().width / 3)
            }
        }
        .padding(.horizontal)
    }
    
    private var iconSelectionSection: some View {
        VStack {
            HStack {
                Text("Icon")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Open", systemImage: "chevron.up") {
                    showMoreIcons.toggle()
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
                .hoverEffect(.highlight)
            }
            .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    let gridSpace: CGFloat = 55
                    LazyHGrid(rows: [GridItem(.fixed(gridSpace)), GridItem(.fixed(gridSpace)), GridItem(.fixed(gridSpace))], spacing: 20) {
                        ForEach(FTAppAssets.defaultIconNames, id: \.self) { iconName in
                            getIconItem(for: iconName)
                                .contentShape([.hoverEffect, .contextMenuPreview], Circle())
                                .hoverEffect(.highlight)
                                .id(iconName)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.iconName = iconName
                                    }
                                }
                        }
                    }
                }
                .contentMargins(12, for: .scrollContent)
                .onReceive(viewModel.$iconName) { iconName in
                    withAnimation {
                        proxy.scrollTo(iconName)
                    }
                }
            }
        }
    }
    
    private var iconsListView: some View {
        WideIconPickerView(showPicker: $showMoreIcons, selectIcon: $viewModel.iconName, onSelectColorTint: viewModel.color)
    }
    
    private var colorPickerSection: some View {
        VStack {
            HStack {
                Text("Color")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack {
                ForEach(FTAppAssets.defaultColors, id: \.self) { defaultColor in
                    getColorItem(for: defaultColor)
                        .contentShape([.hoverEffect, .contextMenuPreview], Circle())
                        .hoverEffect(.highlight)
                    
                    Spacer()
                }
                
                ColorPicker("", selection: $viewModel.color)
                    .labelsHidden()
                    .contentShape([.hoverEffect, .contextMenuPreview], Circle())
                    .hoverEffect(.highlight)
                    .overlay {
                        if !FTAppAssets.defaultColors.contains(viewModel.color) {
                            Image(systemName: "checkmark")
                                .font(.footnote)
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(!FTAppAssets.defaultColors.contains(viewModel.color) ? 1.5 : 1.3)
                    .shadow(radius: 5)
                    .onTapGesture(count: 20, perform: {
                        //Prevents iOS 17 bug
                    })
                    .padding(.leading, 6)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray.opacity(0.15))
            }
        }
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        Button {
            viewModel.save {
                dismiss()
            }
        } label: {
            Label(isAdding ? "Add" : "Update", systemImage: isAdding ? "plus" : "pencil.and.outline")
                .frame(width: 170, height: 50)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .stroke(canBeAddedOrUpdated ? .blue : .gray)
                }
        }
        .hoverEffect(.lift)
        .disabled(!canBeAddedOrUpdated)
        .offset(y: -5)
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func getIconItem(for iconName: String) -> some View {
        FTAppAssets.iconImageOrEpty(name: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .padding(8)
            .background {
                Circle()
                    .fill(viewModel.iconName == iconName ? viewModel.color.opacity(0.3) : .gray.opacity(0.3))
            }
    }
    
    @ViewBuilder
    private func getColorItem(for colorToSet: Color) -> some View {
        Circle()
            .fill(colorToSet)
            .frame(width: 35, height: 35)
            .shadow(radius: 5)
            .onTapGesture {
                withAnimation {
                    viewModel.color = colorToSet
                }
            }
            .overlay {
                if viewModel.color == colorToSet {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(viewModel.color == colorToSet ? 1.1 : 1)
    }
    
    private func dismissKeyboard() {
        nameTextFieldFocus = false
        balanceTextFieldFocus = false
    }
    
    private func onChangeOfBalanceString() {
        var copyString = viewModel.balanceString
        guard !copyString.isEmpty else { return }
        
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        if copyString.contains(" ") {
            copyString.replace(" ", with: "")
        }
        
        guard let floatValue = Float(copyString) else {
            viewModel.balanceString = ""
            return
        }
        
        viewModel.balance = floatValue
        
        if let firstChar = copyString.first, firstChar == "0" {
            viewModel.balanceString.removeFirst()
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = AddingBalanceAccountViewModel(dataManager: dataManager, action: .add)
    
    return AddingBalanceAccauntView(viewModel: viewModel)
}
