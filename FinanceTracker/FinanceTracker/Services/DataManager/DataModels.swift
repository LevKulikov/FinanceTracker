//
//  Item.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.05.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol Named {
    var name: String { get set }
}

enum TransactionsType: String, CaseIterable {
    case spending = "Spendings"
    case income = "Income"
}

//MARK: - BalanceAccount Model
@Model
final class BalanceAccount {
    static let emptyBalanceAccount = BalanceAccount(name: "empty", currency: "RUB", balance: 0, iconName: "", color: .clear)
    
    //MARK: Properties
    @Attribute(.unique) let id: String
    var name: String
    var currency: String
    var balance: Float
    var iconName: String
    @Attribute(.transformable(by: UIColorValueTransformer.self)) var uiColor: UIColor
    
    //MARK: Computed Properties
    var color: Color {
        get {
            .init(uiColor: uiColor)
        }
        set {
            uiColor = .init(newValue)
        }
    }
    
    //MARK: Inits
    init(id: String, name: String, currency: String, balance: Float, iconName: String, uiColor: UIColor) {
        self.id = id
        self.name = name
        self.currency = currency
        self.balance = balance
        self.iconName = iconName
        self.uiColor = uiColor
    }
    
    convenience init(name: String, currency: String, balance: Float, iconName: String, color: Color) {
        let id = UUID().uuidString
        let uiColor = UIColor(color)
        self.init(id: id, name: name, currency: currency, balance: balance, iconName: iconName, uiColor: uiColor)
    }
}

//MARK: - Category Model
@Model
final class Category {
    static let emptyCategory = Category(type: .spending, name: "empty", iconName: "", color: .clear)
    
    //MARK: Properties
    @Attribute(.unique) let id: String
    var typeRawValue: String
    var name: String
    var iconName: String
    @Attribute(.transformable(by: UIColorValueTransformer.self)) var uiColor: UIColor
    
    //MARK: Computed Properties
    var type: TransactionsType? {
        get {
            .init(rawValue: typeRawValue)
        }
        set {
            guard let newValue else {
                print("Category.type new value is nil")
                return
            }
            typeRawValue = newValue.rawValue
        }
    }
    
    var color: Color {
        get {
            .init(uiColor: uiColor)
        }
        set {
            uiColor = .init(newValue)
        }
    }
    
    //MARK: Init
    init(id: String, typeRawValue: String, name: String, iconName: String, uiColor: UIColor) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.name = name
        self.iconName = iconName
        self.uiColor = uiColor
    }
    
    convenience init(type: TransactionsType, name: String, iconName: String, color: Color) {
        let id = UUID().uuidString
        let typeRawValue = type.rawValue
        let uiColor = UIColor(color)
        self.init(id: id, typeRawValue: typeRawValue, name: name, iconName: iconName, uiColor: uiColor)
    }
}

//MARK: - Tag Model
@Model
final class Tag {
    //MARK: Properties
    @Attribute(.unique) let id: String
    var name: String
    @Attribute(.transformable(by: UIColorValueTransformer.self)) var uiColor: UIColor
    
    //MARK: Computed Properties
    var color: Color {
        get {
            .init(uiColor: uiColor)
        }
        set {
            uiColor = .init(newValue)
        }
    }
    
    //MARK: Init
    init(id: String, name: String, uiColor: UIColor) {
        self.id = id
        self.name = name
        self.uiColor = uiColor
    }
    
    convenience init(name: String, color: Color = .init(uiColor: .random)) {
        let id = UUID().uuidString
        let uiColor = UIColor(color)
        self.init(id: id, name: name, uiColor: uiColor)
    }
}

//MARK: - Transaction Model
#warning("BalanceAccount or Category can be deleted. So it is needed to de solved. Solution:\n - For Categoreis, if user wants to delete, say him/her to replace with another Category or Defualt Unidentified, or create 'deleted' flag as property and don't show it to user anymore;\n - For BalanceAccount, create 'deleted' flag as property and don't show it to user anymore ")
@Model
final class Transaction {
    //MARK: Properties
    @Attribute(.unique) let id: String
    private(set) var typeRawValue: String
    var comment: String
    var value: Float
    var date: Date
    var balanceAccount: BalanceAccount
    var category: Category
    var tags: [Tag]
    
    //MARK: Computed Properties
    var type: TransactionsType? {
        get {
            .init(rawValue: typeRawValue)
        }
        set {
            guard let newValue else {
                print("Transaction.type new value is nil")
                return
            }
            typeRawValue = newValue.rawValue
        }
    }
    
    //MARK: Init
    init(id: String, typeRawValue: String, comment: String, value: Float, date: Date, balanceAccount: BalanceAccount, category: Category, tags: [Tag]) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.comment = comment
        self.value = value
        self.date = date
        self.balanceAccount = balanceAccount
        self.category = category
        self.tags = tags
    }
    
    convenience init(type: TransactionsType, comment: String, value: Float, date: Date, balanceAccount: BalanceAccount, category: Category, tags: [Tag]) {
        let id = UUID().uuidString
        let typeRawValue = type.rawValue
        self.init(id: id, typeRawValue: typeRawValue, comment: comment, value: value, date: date, balanceAccount: balanceAccount, category: category, tags: tags)
    }
}

//MARK: - UIColor ValueTransformer
@objc(UIColorValueTransformer)
final class UIColorValueTransformer: ValueTransformer {
    //MARK: ValueTransformer Registration
    static let name = NSValueTransformerName(rawValue: String(describing: UIColorValueTransformer.self))
    
    static func register() {
        let transformer = UIColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
    //MARK: ValueTransformer Methods
    override class func transformedValueClass() -> AnyClass {
        return UIColor.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            print("Failed to transform `UIColor` to `Data`")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        
        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data as Data)
            return color
        } catch {
            print("Failed to transform `Data` to `UIColor`")
            return nil
        }
    }
}
