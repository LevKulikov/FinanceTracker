//
//  TagsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.06.2024.
//

import SwiftUI

struct TagsView: View {
    //MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: TagsViewModel
    @State private var showAddingRow = false
    @FocusState private var tagChangeTextFieldFocused
    @FocusState private var tagAddingTextFieldFocused
    @Namespace private var namespace
    @State private var tagDeletionFlag: Tag?
    @State private var showSettings = false
    
    //MARK: - Initializer
    init(viewModel: TagsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                if showAddingRow {
                    addingTagRow
                }
                
                ForEach(viewModel.tags) { tag in
                    getTagRow(for: tag)
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gear") {
                        showSettings.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .popover(isPresented: $showSettings) {
                        tagDefaultSettingsView
                            .presentationCompactAdaptation(.popover)
                    }
                    
                    Button(showAddingRow ? "Hide" : "Add", systemImage: showAddingRow ? "xmark" : "plus") {
                        tagAddingTextFieldFocused = !showAddingRow
                        withAnimation {
                            showAddingRow.toggle()
                            if viewModel.tagSelected != nil {
                                viewModel.endUpdatingTag()
                            }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.tags.isEmpty, !showAddingRow {
                    VStack {
                        Text("You do not have any saved tag.")
                            .foregroundStyle(.secondary)
                        
                        Text("It is good opportunity to try!")
                            .foregroundStyle(.secondary)
                        
                        Button("Create tag") {
                            withAnimation {
                                showAddingRow.toggle()
                            }
                        }
                        .buttonBorderShape(.capsule)
                        .buttonStyle(.bordered)
                    }
                    .font(.title2)
                }
            }
            .confirmationDialog(
                "Delete tag?",
                isPresented: .init(get: {tagDeletionFlag != nil}, set: { _ in tagDeletionFlag = nil }),
                titleVisibility: .visible) {
                    Button("Delete tag only", role: .destructive) {
                        if let tagDeletionFlag {
                            viewModel.deleteTag(tagDeletionFlag, withAnimation: true)
                        }
                    }
                    
                    Button("Delete with transactions", role: .destructive) {
                        if let tagDeletionFlag {
                            viewModel.deleteTagWithTransactions(tagDeletionFlag, withAnimation: true)
                        }
                    }
                } message: {
                    Text("This action is irretable. There are two ways to delete:\n\n - Delete tag only: only selected tag will be deleted and removed from transactions \n\n - Delete with transactions: tag and transactions marked with this tag will be deleted all together")
                }

        }
    }
    
    //MARK: - Computed View props
    private var tagDefaultSettingsView: some View {
        VStack {
            Toggle("Random color by default", isOn: $viewModel.globalRandomColorToggle)
            
            if !viewModel.globalRandomColorToggle {
                ColorPicker("Default color", selection: $viewModel.tagDefaulColor)
                    .disabled(viewModel.globalRandomColorToggle)
            }
        }
        .padding()
    }
    
    private var addingTagRow: some View {
        VStack {
            HStack {
                Text("#")
                    .bold()
                
                TextField("Updating text field", text: $viewModel.tagName, prompt: Text("Tag name"))
                    .labelsHidden()
                    .focused($tagAddingTextFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            .padding(.bottom, 7)
            
            VStack {
                Toggle("Random color", isOn: $viewModel.randomColorToggle)
                
                if !viewModel.randomColorToggle {
                    Divider()
                    
                    ColorPicker("Select color", selection: $viewModel.tagColor)
                        .disabled(viewModel.randomColorToggle)
                }
                
            }
            .padding(5)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .padding(.horizontal, -5)
            }
            .padding(.bottom, 7)
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    withAnimation {
                        viewModel.endUpdatingTag()
                        showAddingRow = false
                        tagAddingTextFieldFocused = false
                    }
                }
                .tint(.red)
                
                Button("Save") {
                    viewModel.createNewTag()
                    withAnimation {
                        viewModel.endUpdatingTag()
                        showAddingRow = false
                        tagAddingTextFieldFocused = false
                    }
                }
                .tint(.blue)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
    }
    
    //MARK: - Methods
    @ViewBuilder
    private func getTagRow(for tag: Tag) -> some View {
        VStack {
            if viewModel.tagSelected == tag {
                HStack {
                    Text("#")
                        .bold()
                        .matchedGeometryEffect(id: "#sign" + tag.id, in: namespace)
                    
                    TextField("Updating text field", text: $viewModel.tagName, prompt: Text("Tag name"))
                        .labelsHidden()
                        .focused($tagChangeTextFieldFocused)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing)
                        .matchedGeometryEffect(id: "tagname" + tag.id, in: namespace)
                    
                    Spacer()
                    
                    ColorPicker("Color for tag", selection: $viewModel.tagColor)
                        .labelsHidden()
                        .matchedGeometryEffect(id: "tagColor" + tag.id, in: namespace)
                }
                .padding(.top)
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        withAnimation {
                            viewModel.endUpdatingTag()
                            tagChangeTextFieldFocused = false
                        }
                    }
                    .matchedGeometryEffect(id: "cancelButton" + tag.id, in: namespace)
                    .tint(.red)
                    
                    Button("Save") {
                        viewModel.updateSelectedTag()
                        withAnimation {
                            viewModel.endUpdatingTag()
                            tagChangeTextFieldFocused = false
                        }
                    }
                    .matchedGeometryEffect(id: "saveButton" + tag.id, in: namespace)
                    .tint(.blue)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .padding(.bottom)
            } else {
                HStack {
                    Text("#").bold()
                        .matchedGeometryEffect(id: "#sign" + tag.id, in: namespace)
                    
                    Text(tag.name)
                        .matchedGeometryEffect(id: "tagname" + tag.id, in: namespace)
                        .layoutPriority(1)
                    
                    Rectangle()
                        .fill(.clear)
                        .matchedGeometryEffect(id: "cancelButton" + tag.id, in: namespace)
                        .matchedGeometryEffect(id: "saveButton" + tag.id, in: namespace)
                        .matchedGeometryEffect(id: "tagColor" + tag.id, in: namespace)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        if showAddingRow {
                            showAddingRow = false
                        }
                        viewModel.startUpdatingTag(tag)
                        tagChangeTextFieldFocused = true
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        tagDeletionFlag = tag
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        tagDeletionFlag = tag
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(
            viewModel.tagSelected == tag ? LinearGradient(colors: [colorScheme == .light ? Color(.systemBackground) : Color(.systemGray6)], startPoint: .leading, endPoint: .trailing) :
            LinearGradient(
                stops: [.init(color: colorScheme == .light ? Color(.systemBackground) : Color(.systemGray6), location: 0.3), .init(color: tag.color, location: 1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .padding(.horizontal)
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = TagsViewModel(dataManager: dataManger)
    
    return TagsView(viewModel: viewModel)
}
