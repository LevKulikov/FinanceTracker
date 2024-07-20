//
//  AddingBudgetView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.07.2024.
//

import SwiftUI

struct AddingBudgetView: View {
    //MARK: - Properties
    @StateObject private var viewModel: AddingBudgetViewModel
    @State private var showCategoryPicker = false
    @FocusState private var nameTextFieldFocus
    @FocusState private var valueTextFieldFocus
    private var isAdding: Bool {
        if case .add = viewModel.action {
            return true
        }
        return false
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
    }
    
    //MARK: - Computed view props
    private var nameSection: some View {
        VStack {
            HStack {
                Text("Name")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal)
            
            TextField("Budget name (Optional)", text: $viewModel.name, prompt: Text("Enter name here"))
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
                .fill(.ultraThinMaterial)
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
            
            Divider()
            
            
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 10)
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
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = AddingBudgetViewModel(action: .update(budget: .empty), dataManager: dataManager)
    
    return AddingBudgetView(viewModel: viewModel)
}
