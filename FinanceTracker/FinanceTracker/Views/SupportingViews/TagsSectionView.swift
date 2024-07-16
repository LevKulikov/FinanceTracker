//
//  TagsSectionView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 03.06.2024.
//

import SwiftUI

struct TagsSectionView: View {
    @ObservedObject var viewModel: AddingSpendIcomeViewModel
    @Binding var showMoreTagsOptions: Bool
    @FocusState.Binding var focusState: Bool
    
    var body: some View {
        VStack {
            HStack {
                if !showMoreTagsOptions {
                    Text("Tags and comment")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                } else {
                    TextField("", text: $viewModel.searchTagText, prompt: Text("Search or add tag"))
                        .focused($focusState)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.secondary.opacity(0.4))
                                .padding(-5)
                        }
                        .padding(.horizontal, 5)
                }
                
                Button {
                    withAnimation {
                        showMoreTagsOptions.toggle()
                        focusState = showMoreTagsOptions
                    }
                } label: {
                    if showMoreTagsOptions {
                        Label("Close", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.blue)
                    } else {
                        Label("More", systemImage: "chevron.left")
                    }
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
                .hoverEffect(.highlight)
            }
            .padding(.horizontal, 10)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(showMoreTagsOptions ? viewModel.searchedTags : viewModel.availableTags) { tag in
                        let tagIdAdded = viewModel.tags.contains(tag)
                        
                        Text("# \(tag.name)")
                            .foregroundStyle(tagIdAdded ? .primary : .secondary)
                            .bold(tagIdAdded)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(tag.color.opacity(tagIdAdded ? 0.4 : 0.15))
                            }
                            .hoverEffect(.highlight)
                            .onTapGesture {
                                viewModel.addRemoveTag(tag)
                            }
                    }
                    
                    if !viewModel.isThereFullyIdenticalTag && showMoreTagsOptions {
                        Button("Add tag") {
                            viewModel.createNewTag(andSelect: true)
                        }
                        .buttonStyle(.bordered)
                        .hoverEffect(.highlight)
                        .padding(.vertical, -2)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(10)
            .id("existing tags")
        }
    }
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let transactionsTypeSelected: TransactionsType = .spending
    let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, use: .main, transactionsTypeSelected: transactionsTypeSelected, balanceAccount: .emptyBalanceAccount)
    
    @State var showOpt = false
    @FocusState var focusState
    
    return TagsSectionView(viewModel: viewModel, showMoreTagsOptions: $showOpt, focusState: $focusState)
}
