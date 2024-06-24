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
    @Published var randomColorToggle = true
    
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
    
    func startUpdatingTag(_ tag: Tag) {
        tagSelected = tag
        tagName = tag.name
        tagColor = tag.color
    }
    
    func endUpdatingTag() {
        tagSelected = nil
        tagName = ""
        tagColor = .orange
    }
    
    func createNewTag() {
        createNewTag(name: tagName, color: randomColorToggle ? nil : tagColor)
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
    
    func deleteTag(_ tag: Tag, withAnimation: Bool = false) {
        Task {
            await dataManager.deleteTag(tag)
            await fetchTags(withAnimation: withAnimation)
        }
    }
    
    func deleteTagWithTransactions(_ tag: Tag, withAnimation: Bool = false) {
        Task {
            await dataManager.deleteTagWithTransactions(tag)
            await fetchTags(withAnimation: withAnimation)
        }
    }
    
    //MARK: Pivate methods
    @MainActor
    private func fetchTags(withAnimation animated: Bool = false, errorHandler: ((Error) -> Void)? = nil) async {
        let descriptor = FetchDescriptor<Tag>()
        
        do {
            let fetchedTags = try dataManager.fetch(descriptor)
            if animated {
                withAnimation {
                    tags = fetchedTags.reversed()
                }
            } else {
                tags = fetchedTags.reversed()
            }
        } catch {
            errorHandler?(error)
            return
        }
    }
}
