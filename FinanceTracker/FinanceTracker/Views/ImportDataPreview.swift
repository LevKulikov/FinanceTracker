//
//  ImportDataPreview.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 14.08.2024.
//

import SwiftUI

struct ImportDataPreview: View {
    //MARK: - Properties
    private let container: FTDataContainer
    private let deletionAlertBeforSave: Bool
    private let onImportAction: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedField: FTDataContainer.Field = .transactions
    @State private var cancelationAlert = false
    @State private var deletionAlert = false
    @State private var infoPopover = false
    
    //MARK: - Initializer
    init(container: FTDataContainer, deletionAlertBeforSave: Bool = true, onImportAction: @escaping () -> Void) {
        self.container = container
        self.deletionAlertBeforSave = deletionAlertBeforSave
        self.onImportAction = onImportAction
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Why I don't see some information", systemImage: "questionmark.circle") {
                        infoPopover.toggle()
                    }
                    .popover(isPresented: $infoPopover) {
                        Text("Some information cannot be previewed until the imported data is saved to the device. After saving, all information will be available for viewing and editing")
                            .frame(height: 160)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                    }
                }
                
                selectedForEach
                
                Section {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 40)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    fieldPicker
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelationAlert.toggle()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Cancel the import?", isPresented: $cancelationAlert) {
                Button("Yes, cancel", role: .destructive) {
                    dismiss()
                }
                
                Button("No, stay here", role: .cancel) { }
            } message: {
                Text("Imported data will be cleaned")
            }
            .overlay(alignment: .bottom) {
                importButton
                    .confirmationDialog("Import data?", isPresented: $deletionAlert, titleVisibility: .visible) {
                        Button("Import", role: .destructive) {
                            print("Import button pressed")
                            onImportAction()
                            dismiss()
                        }
                    } message: {
                        Text("All stored data will be deleted and replaced with imported data, even it is empty")
                    }
            }
        }
    }
    
    //MARK: - Computed View Properties
    private var fieldPicker: some View {
        Menu(String(localized: selectedField.rawValue), systemImage: "line.3.horizontal.circle") {
            Picker("Imported objects", selection: $selectedField) {
                ForEach(FTDataContainer.Field.allCases) { field in
                    Text(field.rawValue)
                        .tag(field)
                }
            }
        }
        .labelStyle(.titleAndIcon)
        .modifier(RoundedRectMenu())
    }
    
    private var importButton: some View {
        Button {
            if deletionAlertBeforSave {
                deletionAlert.toggle()
            } else {
                onImportAction()
                dismiss()
            }
        } label: {
            Text("Import")
                .bold()
                .frame(height: 30)
                .frame(maxWidth: 600)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .padding(.horizontal)
    }
    
    @MainActor @ViewBuilder
    private var selectedForEach: some View {
        switch selectedField {
        case .transactions:
            if container.transactionContainers.isEmpty {
                ContentUnavailableView(
                    "No transactions imported",
                    systemImage: "folder",
                    description: Text("Check other items using the picker at the top")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(container.transactionContainers.sorted { $0.transaction.date > $1.transaction.date }) { transactionContainer in
                    TransactionRow(transactionContainer: transactionContainer, container: container)
                }
            }
        case .balanceAccounts:
            if container.balanceAccounts.isEmpty {
                ContentUnavailableView(
                    "No balance accounts imported",
                    systemImage: "folder",
                    description: Text("Check other items using the picker at the top")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(container.balanceAccounts) { balanceAccount in
                    rowForBalanceAccount(balanceAccount)
                }
            }
        case .categories:
            if container.categories.isEmpty {
                ContentUnavailableView(
                    "No categories imported",
                    systemImage: "folder",
                    description: Text("Check other items using the picker at the top")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(container.categories.sorted { $0.typeRawValue > $1.typeRawValue }) { category in
                    rowForCategory(category)
                }
            }
        case .tags:
            if container.tags.isEmpty {
                ContentUnavailableView(
                    "No tags imported",
                    systemImage: "folder",
                    description: Text("Check other items using the picker at the top")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(container.tags) { tag in
                    rowForTag(tag)
                }
            }
        case .budgets:
            if container.budgetContainers.isEmpty {
                ContentUnavailableView(
                    "No budgets imported",
                    systemImage: "folder",
                    description: Text("Check other items using the picker at the top")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(container.budgetContainers) { budgetContainer in
                    BudgetRow(budgetContainer: budgetContainer, container: container)
                }
            }
        }
    }
    
    //MARK: - Methods
    private struct TransactionRow: View {
        let transactionContainer: FTDataContainer.TransactionContainer
        let container: FTDataContainer
        @State private var balanceAccount: BalanceAccount?
        @State private var category: Category?
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(transactionContainer.transaction.date.formatted(date: .numeric, time: .omitted))
                        
                    Spacer()
                    
                    if let balanceAccount {
                        Text(balanceAccount.name)
                    }
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                
                HStack {
                    if let category {
                        FTAppAssets.iconImageOrEpty(name: category.iconName)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(category.color)
                    }
                    
                    Text(category?.name ?? "Transaction")
                        .lineLimit(3)
                    
                    Spacer()
                    
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: transactionContainer.transaction.value) ?? "Err")
                        .foregroundStyle(transactionContainer.transaction.type == .spending ? .red : .green)
                    
                    if let balanceAccount {
                        Text(balanceAccount.currency)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    if !transactionContainer.tagIDs.isEmpty {
                        Text("\(transactionContainer.tagIDs.count) \(transactionContainer.tagIDs.count > 1 ? "tags" : "tag")")
                    }
                    
                    if !transactionContainer.tagIDs.isEmpty && !transactionContainer.transaction.comment.isEmpty {
                        Text("+")
                    }
                    
                    if !transactionContainer.transaction.comment.isEmpty {
                        Text("Comment: \(transactionContainer.transaction.comment)")
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
            }
            .task {
                let balanceAccount = container.balanceAccounts.first { $0.id == transactionContainer.balanceAccountID }
                let category = container.categories.first { $0.id == transactionContainer.categoryID }
                
                await MainActor.run {
                    self.balanceAccount = balanceAccount
                    self.category = category
                }
            }
        }
    }
    
    struct BudgetRow: View {
        let budgetContainer: FTDataContainer.BudgetContainer
        let container: FTDataContainer
        @State private var balanceAccount: BalanceAccount?
        @State private var category: Category?
        private var title: String {
            if !budgetContainer.budget.name.isEmpty {
                return budgetContainer.budget.name
            } else {
                if let category {
                    return category.name
                } else {
                    return String(localized: "For all categories")
                }
            }
        }
        
        var body: some View {
            VStack {
                HStack {
                    if let category {
                        FTAppAssets.iconImageOrEpty(name: category.iconName)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(category.color)
                    }
                    
                    Text(title)
                        .lineLimit(3)
                    
                    Spacer()
                    
                    Text(FTFormatters.numberFormatterWithDecimals.string(for: budgetContainer.budget.value) ?? "Err")
                    
                    if let balanceAccount {
                        Text(balanceAccount.currency)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text(budgetContainer.budget.period.localizedString)
                        .layoutPriority(1)
                    
                    Spacer()
                    
                    if let balanceAccount {
                        Text(balanceAccount.name)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
            }
            .task {
                let balanceAccount = container.balanceAccounts.first { $0.id == budgetContainer.balanceAccountID }
                let category = container.categories.first { $0.id == budgetContainer.categoryID }
                
                await MainActor.run {
                    self.balanceAccount = balanceAccount
                    self.category = category
                }
            }
        }
    }
    
    @MainActor @ViewBuilder
    private func rowForBalanceAccount(_ balanceAccount: BalanceAccount) -> some View {
        HStack {
            FTAppAssets.iconImageOrEpty(name: balanceAccount.iconName)
                .frame(width: 20, height: 20)
                .foregroundStyle(balanceAccount.color)
            
            Text(balanceAccount.name)
            
            Spacer()
            
            Text(balanceAccount.currency)
        }
    }
    
    @MainActor @ViewBuilder
    private func rowForCategory(_ category: Category) -> some View {
        HStack {
            FTAppAssets.iconImageOrEpty(name: category.iconName)
                .frame(width: 20, height: 20)
                .foregroundStyle(category.color)
            
            Text(category.name)
            
            Spacer()
            
            Text(category.type?.localizedString ?? "Err")
                .foregroundStyle(category.type == .spending ? .red : .green)
        }
    }
    
    @ViewBuilder
    private func rowForTag(_ tag: Tag) -> some View {
        HStack {
            Text("#")
                .foregroundStyle(tag.color)
                .bold()
            
            Text(tag.name)
            
            Spacer()
        }
    }
}

#Preview {
    let container = FTDataContainer(balanceAccounts: [], categories: [], tags: [], transactionContainers: [], budgetContainers: [])
    let onImportAction: () -> Void = {
        print("Import action")
    }
    return ImportDataPreview(container: container, onImportAction: onImportAction)
}
