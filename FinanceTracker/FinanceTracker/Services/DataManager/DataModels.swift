//
//  Item.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 24.05.2024.
//

import Foundation
import SwiftData
import SwiftUI

enum TransactionsType: String, CaseIterable, Identifiable {
    case spending = "Spendings"
    case income = "Income"
    
    var localizedString: LocalizedStringResource {
        switch self {
        case .spending:
            return "Spendings"
        case .income:
            return "Income"
        }
    }
    
    var id: Self {
        return self
    }
}

enum CodingError: Error {
    case balanceAccountIsNil
    case categoryIsNil
}

struct FTDataContainer: Codable, Identifiable {
    
    struct TransactionContainer: Codable, Identifiable {
        var id = UUID().uuidString
        let transaction: Transaction
        let balanceAccountID: String
        let categoryID: String
        let tagIDs: [String]
        
        init?(transaction: Transaction) {
            self.transaction = transaction
            guard let baID = transaction.balanceAccount?.id else { return nil}
            self.balanceAccountID = baID
            guard let categoryID = transaction.category?.id else { return nil }
            self.categoryID = categoryID
            self.tagIDs = transaction.tags.map(\.id)
        }
    }
    
    struct BudgetContainer: Codable, Identifiable {
        var id = UUID().uuidString
        let budget: Budget
        let balanceAccountID: String
        let categoryID: String?
        
        init?(budget: Budget) {
            self.budget = budget
            guard let baID = budget.balanceAccount?.id else { return nil }
            self.balanceAccountID = baID
            self.categoryID = budget.category?.id
        }
    }
    
    var id = UUID().uuidString
    
    let balanceAccounts: [BalanceAccount]
    let categories: [Category]
    let tags: [Tag]
    let transactionContainers: [TransactionContainer]
    let budgetContainers: [BudgetContainer]
    
    init(balanceAccounts: [BalanceAccount], categories: [Category], tags: [Tag], transactionContainers: [TransactionContainer], budgetContainers: [BudgetContainer]) {
        self.balanceAccounts = balanceAccounts
        self.categories = categories
        self.tags = tags
        self.transactionContainers = transactionContainers
        self.budgetContainers = budgetContainers
    }
    
    enum Field: LocalizedStringResource, Codable, CaseIterable, Identifiable {
        case transactions = "Transactions"
        case balanceAccounts = "Balance Accounts"
        case categories = "Categories"
        case tags = "Tags"
        case budgets = "Budgets"
        
        var id: Self {
            return self
        }
    }
}

//MARK: - BalanceAccount Model
@Model
final class BalanceAccount: @unchecked Sendable, Codable {
    static let emptyBalanceAccount = BalanceAccount(name: "empty", currency: "RUB", balance: 0, iconName: "", color: .clear)
    
    //MARK: Properties
    @Attribute(.unique) var id: String
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
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case id
        case name
        case currency
        case balance
        case iconName
        case uiColor
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        currency = try container.decode(String.self, forKey: .currency)
        balance = try container.decode(Float.self, forKey: .balance)
        iconName = try container.decode(String.self, forKey: .iconName)
        
        let colorData = try container.decode(Data.self, forKey: .uiColor)
        if let uiColor = UIColorValueTransformer().reverseTransformedValue(colorData) as? UIColor {
            self.uiColor = uiColor
        } else {
            self.uiColor = UIColor(.init(uiColor: .random))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(currency, forKey: .currency)
        try container.encode(balance, forKey: .balance)
        try container.encode(iconName, forKey: .iconName)
        
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .uiColor)
    }
}

//MARK: - Category Model
@Model
final class Category: @unchecked Sendable, Codable {
    static let emptyCategory = Category(type: .spending, name: "empty", iconName: "", color: .clear, placement: 0)
    
    //MARK: Properties
    @Attribute(.unique) var id: String
    var typeRawValue: String
    var name: String
    var iconName: String
    var placement: Int = 0
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
    init(id: String, typeRawValue: String, name: String, iconName: String, placement: Int, uiColor: UIColor) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.name = name
        self.iconName = iconName
        self.placement = placement
        self.uiColor = uiColor
    }
    
    convenience init(type: TransactionsType, name: String, iconName: String, color: Color, placement: Int) {
        let id = UUID().uuidString
        let typeRawValue = type.rawValue
        let uiColor = UIColor(color)
        self.init(id: id, typeRawValue: typeRawValue, name: name, iconName: iconName, placement: placement, uiColor: uiColor)
    }
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case id
        case typeRawValue
        case name
        case iconName
        case placement
        case uiColor
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        typeRawValue = try container.decode(String.self, forKey: .typeRawValue)
        name = try container.decode(String.self, forKey: .name)
        iconName = try container.decode(String.self, forKey: .iconName)
        placement = try container.decode(Int.self, forKey: .placement)
        
        let colorData = try container.decode(Data.self, forKey: .uiColor)
        if let uiColor = UIColorValueTransformer().reverseTransformedValue(colorData) as? UIColor {
            self.uiColor = uiColor
        } else {
            self.uiColor = UIColor(.init(uiColor: .random))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(typeRawValue, forKey: .typeRawValue)
        try container.encode(name, forKey: .name)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(placement, forKey: .placement)
        
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .uiColor)
    }
}

//MARK: - Tag Model
@Model
final class Tag: @unchecked Sendable, Codable {
    //MARK: Properties
    @Attribute(.unique) var id: String
    var name: String
    @Attribute(.transformable(by: UIColorValueTransformer.self)) var uiColor: UIColor
    var transactions: [Transaction] = []
    
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
    init(id: String, name: String, uiColor: UIColor, transactions: [Transaction]) {
        self.id = id
        self.name = name
        self.uiColor = uiColor
        self.transactions = transactions
    }
    
    convenience init(name: String, color: Color? = nil, transactions: [Transaction] = []) {
        let id = UUID().uuidString
        let uiColor = UIColor(color == nil ? .init(uiColor: .random) : color!)
        self.init(id: id, name: name, uiColor: uiColor, transactions: transactions)
    }
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case id
        case name
        case uiColor
        case transactions
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        transactions = try container.decode([Transaction].self, forKey: .transactions)
        
        let colorData = try container.decode(Data.self, forKey: .uiColor)
        if let uiColor = UIColorValueTransformer().reverseTransformedValue(colorData) as? UIColor {
            self.uiColor = uiColor
        } else {
            self.uiColor = UIColor(.init(uiColor: .random))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode([Transaction](), forKey: .transactions) //Encodes empty transactions array to prevent encoding cycle (encode Tag -> Transaction -> same Tag -> same Transaction ...
        
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .uiColor)
    }
}

//MARK: - Transaction Model
@Model
final class Transaction: @unchecked Sendable, Codable {
    //MARK: Properties
    @Attribute(.unique) var id: String
    private(set) var typeRawValue: String
    var comment: String
    var value: Float
    var date: Date
    private(set) var balanceAccount: BalanceAccount?
    private(set) var category: Category?
    @Relationship(inverse: \Tag.transactions) private(set) var tags: [Tag] = []
    
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
        setBalanceAccount(balanceAccount)
        setCategory(category)
        setTags(tags)
    }
    
    convenience init(type: TransactionsType, comment: String, value: Float, date: Date, balanceAccount: BalanceAccount, category: Category, tags: [Tag]) {
        let id = UUID().uuidString
        let typeRawValue = type.rawValue
        self.init(id: id, typeRawValue: typeRawValue, comment: comment, value: value, date: date, balanceAccount: balanceAccount, category: category, tags: tags)
    }
    
    func setBalanceAccount(_ balanceAccount: BalanceAccount) {
        self.balanceAccount = balanceAccount
    }
    
    func setCategory(_ category: Category) {
        self.category = category
    }
    
    func setTags(_ tags: [Tag]) {
        self.tags = tags
    }
    
    func removeTag(_ tag: Tag) {
        tags.removeAll { $0 == tag }
    }
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case id
        case typeRawValue
        case comment
        case value
        case date
        case balanceAccount
        case category
        case tags
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        typeRawValue = try container.decode(String.self, forKey: .typeRawValue)
        comment = try container.decode(String.self, forKey: .comment)
        value = try container.decode(Float.self, forKey: .value)
        date = try container.decode(Date.self, forKey: .date)
        balanceAccount = try container.decode(BalanceAccount.self, forKey: .balanceAccount)
        category = try container.decode(Category.self, forKey: .category)
        tags = try container.decode([Tag].self, forKey: .tags)
    }
    
    func encode(to encoder: any Encoder) throws {
        guard let balanceAccount else {
            throw CodingError.balanceAccountIsNil
        }
        guard let category else {
            throw CodingError.categoryIsNil
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(typeRawValue, forKey: .typeRawValue)
        try container.encode(comment, forKey: .comment)
        try container.encode(value, forKey: .value)
        try container.encode(date, forKey: .date)
        try container.encode(balanceAccount, forKey: .balanceAccount)
        try container.encode(category, forKey: .category)
        try container.encode(tags, forKey: .tags)
    }
}

@Model
final class Budget: @unchecked Sendable, Codable {
    static let empty = Budget(name: "empty", value: 1000, period: .week, category: nil, balanceAccount: .emptyBalanceAccount)
    
    enum Period: CaseIterable, Identifiable, Codable {
        case week
        case month
        case year
        
        var id: Self {
            return self
        }
        
        var localizedString: LocalizedStringResource {
            switch self {
            case .week:
                return "For a week"
            case .month:
                return "For a month"
            case .year:
                return "For a year"
            }
        }
    }
    
    //MARK: - Properties
    @Attribute(.unique) var id: String
    var name: String
    var value: Float
    var period: Period
    /// Nil meens that budget is for all categories
    private(set) var category: Category?
    private(set) var balanceAccount: BalanceAccount?
    
    //MARK: - Initializer
    init(id: String, name: String, value: Float, period: Period, category: Category?, balanceAccount: BalanceAccount) {
        self.id = id
        self.name = name
        self.value = value
        self.period = period
        setCategory(category)
        setBalanceAccount(balanceAccount)
    }
    
    convenience init(name: String, value: Float, period: Period, category: Category?, balanceAccount: BalanceAccount) {
        let id = UUID().uuidString
        self.init(id: id, name: name, value: value, period: period, category: category, balanceAccount: balanceAccount)
    }
    
    //MARK: - Methods
    /// Set nil if budget is for all categories
    func setCategory(_ category: Category?) {
        self.category = category
    }
    
    func setBalanceAccount(_ balanceAccount: BalanceAccount) {
        self.balanceAccount = balanceAccount
    }
    
    //MARK: Codable
    enum CodingKeys: CodingKey {
        case id
        case name
        case value
        case period
        case category
        case balanceAccount
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(Float.self, forKey: .value)
        period = try container.decode(Period.self, forKey: .period)
        balanceAccount = try container.decode(BalanceAccount.self, forKey: .balanceAccount)
        do {
            category = try container.decode(Optional<Category>.self, forKey: .category)
        } catch {
            category = nil
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        guard let balanceAccount else {
            throw CodingError.balanceAccountIsNil
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(period, forKey: .period)
        try container.encode(category, forKey: .category)
        try container.encode(balanceAccount, forKey: .balanceAccount)
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
