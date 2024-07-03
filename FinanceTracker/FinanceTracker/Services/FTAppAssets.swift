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
    
    static var availableDateRange: ClosedRange<Date> {
        Date(timeIntervalSince1970: 0)...(Date.now.endOfDay() ?? .now)
    }
    
    static let defaultColors: [Color] = [
        .red,
        .blue,
        .green,
        .orange,
        .purple,
        .yellow,
    ]
    
    static let appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    static let currentUserDevise: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    
    static let currnetUserDeviseName: String = UIDevice.current.name
    
    //MARK: Methods
    static func iconUIImage(name: String, bundle: String = "IconImages.bundle") -> UIImage? {
        let location = bundle + "/" + name
        let uiImage = UIImage(named: location)
        return uiImage?.withRenderingMode(.alwaysTemplate)
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
    
    static func iconImageOrEpty(name: String, bundle: String = "IconImages.bundle") -> Image {
        let uiImage = iconUIImage(name: name, bundle: bundle)
        if let uiImage {
            return Image(uiImage: uiImage).resizable()
        } else {
            let defaultUiImage = UIImage(systemName: "xmark")!
            return Image(uiImage: defaultUiImage)
        }
    }
    
    static func getScreenSize() -> CGSize {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .zero }
        return windowScene.screen.bounds.size
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
