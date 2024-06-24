//
//  TagsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.06.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol TagsViewModelDelegate: AnyObject {
    
}

final class TagsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any TagsViewModelDelegate)?
    
    //MARK: Pivate properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published properties
    @Published private(set) var tags: [Tag] = []
    @Published var tagSelected: Tag?
    @Published var tagName: String = ""
    @Published var tagColor: Color = .orange
    @FocusState var tagChangeTextFieldFocused {
        didSet {
            if tagChangeTextFieldFocused {
                tagName = tagSelected?.name ?? ""
                tagColor = tagSelected?.color ?? .orange
            }
        }
    }
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol) {
        self.dataManager = dataManager
        fetchData(withAnimation: true)
    }
    
    //MARK: - Methods
    func fetchData(withAnimation: Bool = false, completionHandler: (() -> Void)? = nil) {
        Task {
            await fetchTags(withAnimation: withAnimation)
            completionHandler?()
        }
    }
    
    func createNewTag(name: String, color: Color? = nil) {
        guard !name.isEmpty else { return }
        
        let newTag: Tag
        if let color {
            newTag = Tag(name: name, color: color)
        } else {
            newTag = Tag(name: name)
        }
        
        Task {
            await dataManager.insert(newTag)
            await fetchTags()
        }
    }
    
    func updateSelectedTag() {
        guard let tagSelected else { return }
        tagSelected.name = tagName
        tagSelected.color = tagColor
        Task {
            do {
                try await dataManager.save()
                await fetchTags()
            } catch {
                print(error)
                return
            }
        }
    }
    
    func deleteTag(_ tag: Tag) {
        Task {
            await dataManager.deleteTag(tag)
            await fetchTags()
        }
    }
    
    func deleteTagWithTransactions(_ tag: Tag) {
        Task {
            await dataManager.deleteTagWithTransactions(tag)
            await fetchTags()
        }
    }
    
    //MARK: Pivate methods
    @MainActor
    private func fetchTags(withAnimation animated: Bool = false, errorHandler: ((Error) -> Void)? = nil) async {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        
        do {
            let fetchedTags = try dataManager.fetch(descriptor)
            if animated {
                withAnimation {
                    tags = fetchedTags
                }
            } else {
                tags = fetchedTags
            }
        } catch {
            errorHandler?(error)
            return
        }
    }
}
