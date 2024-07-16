//
//  CategoryItemView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 03.06.2024.
//

import SwiftUI

struct CategoryItemView: View {
    let category: Category
    @Binding var selectedCategory: Category?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        stops: [.init(color: category.color.opacity(selectedCategory == category ? 0.4 : 0.2), location: 0.7),
                                .init(color: category.color, location: 1.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [category.color.opacity(selectedCategory == category ? 0.5 : 1), category.color.opacity(0.1)],
                                         startPoint: .leading,
                                         endPoint: .trailing)
                    )
                    .overlay {
                        getCategoryImage(for: category)
                    }
                    .frame(width: 70)
                
                Spacer()
                
                Text(category.name)
                    .bold(selectedCategory == category ? true : false)
                    .font(.footnote)
                    .lineLimit(1)
                    .frame(width: 90)
            }
            .padding(.vertical, 12)
        }
        .frame(width: 100, height: 130)
        .id(category)
        .scaleEffect(selectedCategory == category ? 1.1 : 1)
        .padding(.horizontal, selectedCategory == category ? 6 : 0)
        .contentShape([.hoverEffect, .contextMenuPreview], RoundedRectangle(cornerRadius: 10.0))
    }
    
    @ViewBuilder
    private func getCategoryImage(for category: Category) -> some View {
        let frameDimention: CGFloat = 50
        
        if let uiImage = FTAppAssets.iconUIImage(name: category.iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: frameDimention, height: frameDimention)
        } else {
            FTAppAssets.emptyIconImage(xMarkFont: .title2)
                .frame(width: frameDimention - 10, height: frameDimention - 10)
        }
    }
}

#Preview {
    let category = Category(type: .spending, name: "Show me", iconName: "001-gamepad", color: .cyan, placement: 1)
    @State var picked: Category? = category
    
    return CategoryItemView(category: category, selectedCategory: $picked)
}
