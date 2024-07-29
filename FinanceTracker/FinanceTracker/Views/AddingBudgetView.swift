//
//  AddingBudgetView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.07.2024.
//

import SwiftUI

struct AddingBudgetView: View {
    //MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: AddingBudgetViewModel
    @State private var showCategoryPicker = false
    @State private var saveAlert = false
    @FocusState private var nameTextFieldFocus
    @FocusState private var valueTextFieldFocus
    private let userDevice = FTAppAssets.currentUserDevise
    private var isAdding: Bool {
        if case .add = viewModel.action {
            return true
        }
        return false
    }
    private var canBeAddedOrUpdated: Bool {
        viewModel.value > 0
    }
    private var backgroundColor: Color {
        colorScheme == .light ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }
    private var sectionColor: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }
    
    //MARK: - Initializer
    init(viewModel: AddingBudgetViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        ScrollView {
            nameSection
            
            Divider()
                .padding(.horizontal)
                .padding(.bottom)
            
            valueSection
                .padding(.bottom)
            
            categoryAndPeriodSection
                .padding(.bottom)
            
            balanceAccountSection
                .padding(.bottom)
            
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(isAdding ? "New budget" : "Budget")
        .sheet(isPresented: $showCategoryPicker) {
            WideCategoryPickerView(
                categories: viewModel.allCategories,
                selecetedCategory: $viewModel.category,
                show: $showCategoryPicker) { category in
                    viewModel.category = category
                    showCategoryPicker = false
                } contextMenuContent: { _ in
                    EmptyView()
                }
                .presentationBackground(Material.thin)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(30)

        }
        .alert("Some save error happened", isPresented: $saveAlert) {
            Button("Ok") {}
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("", systemImage: "keyboard.chevron.compact.down.fill", action: dismissKeyboard)
                    .foregroundStyle(.secondary)
                    .labelsHidden()
            }
        }
        .overlay(alignment: .bottom) {
            addButton
                .offset(y: userDevice == .phone ? 0 : -60)
        }
        .background { backgroundColor.ignoresSafeArea() }
    }
    
    //MARK: - Computed view props
    private var nameSection: some View {
        VStack {
            TextField("Budget name", text: $viewModel.name, prompt: Text("Budget name (Optional)"))
                .focused($nameTextFieldFocus)
                .font(.title2)
                .padding(.horizontal)
        }
    }
    
    private var valueSection: some View {
        HStack {
            TextField("0", text: $viewModel.valueString)
                .focused($valueTextFieldFocus)
                .keyboardType(.decimalPad)
                .autocorrectionDisabled()
                .onChange(of: viewModel.valueString, onChangeOfValueString)
                .font(.title)
                .onSubmit {
                    viewModel.valueString = FTFormatters
                        .numberFormatterWithDecimals
                        .string(for: viewModel.value) ?? ""
                }
            
            Text(viewModel.balanceAccount.currency)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(sectionColor)
                .onTapGesture {
                    valueTextFieldFocus = true
                }
        }
        .padding(.horizontal, 10)
    }
    
    private var categoryAndPeriodSection: some View {
        VStack {
            HStack {
                Text("Category")
                    .font(.title3)
                    .layoutPriority(1)
                
                Spacer()
                
                Menu(viewModel.category == nil ? "All" : viewModel.category!.name) {
                    Button("Select") {
                        showCategoryPicker = true
                    }
                    
                    Button("For all categories") {
                        viewModel.category = nil
                    }
                }
                .modifier(RoundedRectMenu())
                .tint(viewModel.category == nil ? .blue : viewModel.category!.color)
            }
            .padding(.bottom)
            
            
            Picker("Budget period", selection: $viewModel.period) {
                ForEach(Budget.Period.allCases) { period in
                    Text(period.localizedString)
                        .tag(period)
                }
            }
            .labelStyle(.iconOnly)
            .pickerStyle(.segmented)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(sectionColor)
        }
        .padding(.horizontal, 10)
    }
    
    private var balanceAccountSection: some View {
        HStack {
            Text("Balance account")
                .font(.title3)
                .layoutPriority(1)
            
            Spacer()
            
            Menu(viewModel.balanceAccount.name) {
                Picker("Balance account picker", selection: $viewModel.balanceAccount) {
                    ForEach(viewModel.allBalanceAccounts) { balanceAccount in
                        HStack {
                            Text(balanceAccount.name)
                            
                            if let uiImage = FTAppAssets.iconUIImage(name: balanceAccount.iconName) {
                                Image(uiImage: uiImage)
                            } else {
                                Image(systemName: "xmark")
                            }
                        }
                        .tag(balanceAccount)
                    }
                }
            }
            .modifier(RoundedRectMenu())
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(sectionColor)
        }
        .padding(.horizontal, 10)
    }
    
    private var addButton: some View {
        Button {
            do {
                try viewModel.saveBudget {
                    dismiss()
                }
            } catch {
                saveAlert = true
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
        .ignoresSafeArea(.keyboard)
    }
    
    //MARK: - Methods
    private func onChangeOfValueString() {
        var copyString = viewModel.valueString
        guard !copyString.isEmpty else { return }
        
        if copyString.contains(",") {
            copyString.replace(",", with: ".")
        }
        
        if copyString.contains(" ") {
            copyString.replace(" ", with: "")
        }
        
        guard let floatValue = Float(copyString) else {
            viewModel.valueString = ""
            return
        }
        
        viewModel.value = floatValue
        
        if let firstChar = copyString.first, firstChar == "0" {
            viewModel.valueString.removeFirst()
        }
    }
    
    private func dismissKeyboard() {
        nameTextFieldFocus = false
        valueTextFieldFocus = false
    }
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AddingBudgetViewModel(action: .add(.emptyBalanceAccount), dataManager: dataManager)
    
    return NavigationStack { AddingBudgetView(viewModel: viewModel) }
}
