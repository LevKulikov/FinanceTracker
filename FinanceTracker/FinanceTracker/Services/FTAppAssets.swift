//
//  FTAppAssets.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 06.06.2024.
//

import Foundation
import SwiftUI

struct FTAppAssets {
    //MARK: Properteis
    static var defaultIconNames: [String] = /*["testIcon", "dollarInCircle", "dollarThreeCash", "database", "wallet"]*/ getIconNames()
    
    //MARK: Methods
    static func iconUIImage(name: String, bundle: String = "IconImages.bundle") -> UIImage? {
        let location = bundle + "/" + name
        let uiImage = UIImage(named: location)
        return uiImage
    }
    
    @ViewBuilder
    static func emptyIconImage(xMarkFont: Font = .title) -> some View {
        Image(systemName: "circle")
            .resizable()
            .scaledToFit()
            .overlay {
                Image(systemName: "xmark")
                    .font(xMarkFont)
                    .bold()
            }
    }
    
    @ViewBuilder
    static func iconImageOrEpty(name: String, bundle: String = "IconImages.bundle") -> Image {
        let uiImage: UIImage = iconUIImage(name: name, bundle: bundle) ?? UIImage(systemName: "xmark")!
        Image(uiImage: uiImage)
    }
    
    private static func getIconNames() -> [String] {
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent("IconImages.bundle")
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)
            return contents.map { String($0.lastPathComponent) }
        } catch let error {
            print(error)
            return []
        }
    }
}
