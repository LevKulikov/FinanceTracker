//
//  FTAppAssets.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 06.06.2024.
//

import Foundation
import SwiftUI

struct Currency: Codable, Identifiable, Hashable {
    var id: String {
        return code
    }
    
    let symbol: String
    let name: String
    let code: String
}

@MainActor
struct FTAppAssets {
    //MARK: Properteis
    nonisolated static let defaultIconNames: [String] = /*["testIcon", "dollarInCircle", "dollarThreeCash", "database", "wallet"]*/ getIconNames()
    nonisolated static let maxCustomSheetWidth: CGFloat = 600
    nonisolated static let maxCustomSheetHeight: CGFloat = 900
    
    nonisolated static var availableDateRange: ClosedRange<Date> {
        Date(timeIntervalSince1970: 0)...(Date.now.endOfDay() ?? .now)
    }
    
    nonisolated static let defaultColors: [Color] = [
        .red,
        .blue,
        .green,
        .orange,
        .purple,
        .yellow,
    ]
    
    nonisolated static let appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    static let currentUserDevise: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    
    static let currnetUserDeviseName: String = UIDevice.current.name
    
    nonisolated static let currencies = [
        Currency(
            symbol: "Bs",
            name: "Bolivian Boliviano",
            code: "BOB"
        ),
        Currency(
            symbol: "₲",
            name: "Paraguayan Guarani",
            code: "PYG"
        ),
        Currency(
            symbol: "Nkr",
            name: "Norwegian Krone",
            code: "NOK"
        ),
        Currency(
            symbol: "BN$",
            name: "Brunei Dollar",
            code: "BND"
        ),
        Currency(
            symbol: "JD",
            name: "Jordanian Dinar",
            code: "JOD"
        ),
        Currency(
            symbol: "QR",
            name: "Qatari Rial",
            code: "QAR"
        ),
        Currency(
            symbol: "Ssh",
            name: "Somali Shilling",
            code: "SOS"
        ),
        Currency(
            symbol: "C$",
            name: "Nicaraguan Córdoba",
            code: "NIO"
        ),
        Currency(
            symbol: "NT$",
            name: "New Taiwan Dollar",
            code: "TWD"
        ),
        Currency(
            symbol: "B/.",
            name: "Panamanian Balboa",
            code: "PAB"
        ),
        Currency(
            symbol: "MMK",
            name: "Myanma Kyat",
            code: "MMK"
        ),
        Currency(
            symbol: "Rs",
            name: "Indian Rupee",
            code: "INR"
        ),
        Currency(
            symbol: "$",
            name: "US Dollar",
            code: "USD"
        ),
        Currency(
            symbol: "AMD",
            name: "Armenian Dram",
            code: "AMD"
        ),
        Currency(
            symbol: "T$",
            name: "Tongan Paʻanga",
            code: "TOP"
        ),
        Currency(
            symbol: "din.",
            name: "Serbian Dinar",
            code: "RSD"
        ),
        Currency(
            symbol: "DT",
            name: "Tunisian Dinar",
            code: "TND"
        ),
        Currency(
            symbol: "MKD",
            name: "Macedonian Denar",
            code: "MKD"
        ),
        Currency(
            symbol: "RWF",
            name: "Rwandan Franc",
            code: "RWF"
        ),
        Currency(
            symbol: "ALL",
            name: "Albanian Lek",
            code: "ALL"
        ),
        Currency(
            symbol: "IQD",
            name: "Iraqi Dinar",
            code: "IQD"
        ),
        Currency(
            symbol: "USh",
            name: "Ugandan Shilling",
            code: "UGX"
        ),
        Currency(
            symbol: "MX$",
            name: "Mexican Peso",
            code: "MXN"
        ),
        Currency(
            symbol: "Skr",
            name: "Swedish Krona",
            code: "SEK"
        ),
        Currency(
            symbol: "£",
            name: "British Pound Sterling",
            code: "GBP"
        ),
        Currency(
            symbol: "J$",
            name: "Jamaican Dollar",
            code: "JMD"
        ),
        Currency(
            symbol: "S$",
            name: "Singapore Dollar",
            code: "SGD"
        ),
        Currency(
            symbol: "GH₵",
            name: "Ghanaian Cedi",
            code: "GHS"
        ),
        Currency(
            symbol: "Ls",
            name: "Latvian Lats",
            code: "LVL"
        ),
        Currency(
            symbol: "CL$",
            name: "Chilean Peso",
            code: "CLP"
        ),
        Currency(
            symbol: "kn",
            name: "Croatian Kuna",
            code: "HRK"
        ),
        Currency(
            symbol: "IRR",
            name: "Iranian Rial",
            code: "IRR"
        ),
        Currency(
            symbol: "UZS",
            name: "Uzbekistan Som",
            code: "UZS"
        ),
        Currency(
            symbol: "SLRs",
            name: "Sri Lankan Rupee",
            code: "LKR"
        ),
        Currency(
            symbol: "EGP",
            name: "Egyptian Pound",
            code: "EGP"
        ),
        Currency(
            symbol: "NZ$",
            name: "New Zealand Dollar",
            code: "NZD"
        ),
        Currency(
            symbol: "KD",
            name: "Kuwaiti Dinar",
            code: "KWD"
        ),
        Currency(
            symbol: "Dkr",
            name: "Danish Krone",
            code: "DKK"
        ),
        Currency(
            symbol: "Fdj",
            name: "Djiboutian Franc",
            code: "DJF"
        ),
        Currency(
            symbol: "FG",
            name: "Guinean Franc",
            code: "GNF"
        ),
        Currency(
            symbol: "₦",
            name: "Nigerian Naira",
            code: "NGN"
        ),
        Currency(
            symbol: "Lt",
            name: "Lithuanian Litas",
            code: "LTL"
        ),
        Currency(
            symbol: "DA",
            name: "Algerian Dinar",
            code: "DZD"
        ),
        Currency(
            symbol: "BZ$",
            name: "Belize Dollar",
            code: "BZD"
        ),
        Currency(
            symbol: "zł",
            name: "Polish Zloty",
            code: "PLN"
        ),
        Currency(
            symbol: "₴",
            name: "Ukrainian Hryvnia",
            code: "UAH"
        ),
        Currency(
            symbol: "MDL",
            name: "Moldovan Leu",
            code: "MDL"
        ),
        Currency(
            symbol: "TL",
            name: "Turkish Lira",
            code: "TRY"
        ),
        Currency(
            symbol: "L.L.",
            name: "Lebanese Pound",
            code: "LBP"
        ),
        Currency(
            symbol: "Br",
            name: "Ethiopian Birr",
            code: "ETB"
        ),
        Currency(
            symbol: "FCFA",
            name: "CFA Franc BEAC",
            code: "XAF"
        ),
        Currency(
            symbol: "HNL",
            name: "Honduran Lempira",
            code: "HNL"
        ),
        Currency(
            symbol: "MGA",
            name: "Malagasy Ariary",
            code: "MGA"
        ),
        Currency(
            symbol: "Br",
            name: "Belarusian Ruble",
            code: "BYN"
        ),
        Currency(
            symbol: "CHF",
            name: "Swiss Franc",
            code: "CHF"
        ),
        Currency(
            symbol: "CF",
            name: "Comorian Franc",
            code: "KMF"
        ),
        Currency(
            symbol: "R$",
            name: "Brazilian Real",
            code: "BRL"
        ),
        Currency(
            symbol: "¥",
            name: "Japanese Yen",
            code: "JPY"
        ),
        Currency(
            symbol: "N$",
            name: "Namibian Dollar",
            code: "NAD"
        ),
        Currency(
            symbol: "Ikr",
            name: "Icelandic Króna",
            code: "ISK"
        ),
        Currency(
            symbol: "OMR",
            name: "Omani Rial",
            code: "OMR"
        ),
        Currency(
            symbol: "CV$",
            name: "Cape Verdean Escudo",
            code: "CVE"
        ),
        Currency(
            symbol: "€",
            name: "Euro",
            code: "EUR"
        ),
        Currency(
            symbol: "KM",
            name: "Bosnia-Herzegovina Convertible Mark",
            code: "BAM"
        ),
        Currency(
            symbol: "₽",
            name: "Russian Ruble",
            code: "RUB"
        ),
        Currency(
            symbol: "Ekr",
            name: "Estonian Kroon",
            code: "EEK"
        ),
        Currency(
            symbol: "BGN",
            name: "Bulgarian Lev",
            code: "BGN"
        ),
        Currency(
            symbol: "₡",
            name: "Costa Rican Colón",
            code: "CRC"
        ),
        Currency(
            symbol: "BWP",
            name: "Botswanan Pula",
            code: "BWP"
        ),
        Currency(
            symbol: "$U",
            name: "Uruguayan Peso",
            code: "UYU"
        ),
        Currency(
            symbol: "MTn",
            name: "Mozambican Metical",
            code: "MZN"
        ),
        Currency(
            symbol: "NPRs",
            name: "Nepalese Rupee",
            code: "NPR"
        ),
        Currency(
            symbol: "Nfk",
            name: "Eritrean Nakfa",
            code: "ERN"
        ),
        Currency(
            symbol: "TT$",
            name: "Trinidad and Tobago Dollar",
            code: "TTD"
        ),
        Currency(
            symbol: "CFA",
            name: "CFA Franc BCEAO",
            code: "XOF"
        ),
        Currency(
            symbol: "฿",
            name: "Thai Baht",
            code: "THB"
        ),
        Currency(
            symbol: "KHR",
            name: "Cambodian Riel",
            code: "KHR"
        ),
        Currency(
            symbol: "GEL",
            name: "Georgian Lari",
            code: "GEL"
        ),
        Currency(
            symbol: "Ksh",
            name: "Kenyan Shilling",
            code: "KES"
        ),
        Currency(
            symbol: "CA$",
            name: "Canadian Dollar",
            code: "CAD"
        ),
        Currency(
            symbol: "₫",
            name: "Vietnamese Dong",
            code: "VND"
        ),
        Currency(
            symbol: "د.إ",
            name: "United Arab Emirates Dirham",
            code: "AED"
        ),
        Currency(
            symbol: "HK$",
            name: "Hong Kong Dollar",
            code: "HKD"
        ),
        Currency(
            symbol: "man.",
            name: "Azerbaijani Manat",
            code: "AZN"
        ),
        Currency(
            symbol: "YR",
            name: "Yemeni Rial",
            code: "YER"
        ),
        Currency(
            symbol: "₩",
            name: "South Korean Won",
            code: "KRW"
        ),
        Currency(
            symbol: "₱",
            name: "Philippine Peso",
            code: "PHP"
        ),
        Currency(
            symbol: "Af",
            name: "Afghan Afghani",
            code: "AFN"
        ),
        Currency(
            symbol: "BD",
            name: "Bahraini Dinar",
            code: "BHD"
        ),
        Currency(
            symbol: "LD",
            name: "Libyan Dinar",
            code: "LYD"
        ),
        Currency(
            symbol: "Ft",
            name: "Hungarian Forint",
            code: "HUF"
        ),
        Currency(
            symbol: "PKRs",
            name: "Pakistani Rupee",
            code: "PKR"
        ),
        Currency(
            symbol: "FBu",
            name: "Burundian Franc",
            code: "BIF"
        ),
        Currency(
            symbol: "S/.",
            name: "Peruvian Nuevo Sol",
            code: "PEN"
        ),
        Currency(
            symbol: "Kč",
            name: "Czech Republic Koruna",
            code: "CZK"
        ),
        Currency(
            symbol: "SY£",
            name: "Syrian Pound",
            code: "SYP"
        ),
        Currency(
            symbol: "GTQ",
            name: "Guatemalan Quetzal",
            code: "GTQ"
        ),
        Currency(
            symbol: "Rp",
            name: "Indonesian Rupiah",
            code: "IDR"
        ),
        Currency(
            symbol: "RD$",
            name: "Dominican Peso",
            code: "DOP"
        ),
        Currency(
            symbol: "AR$",
            name: "Argentine Peso",
            code: "ARS"
        ),
        Currency(
            symbol: "AU$",
            name: "Australian Dollar",
            code: "AUD"
        ),
        Currency(
            symbol: "ZK",
            name: "Zambian Kwacha",
            code: "ZMK"
        ),
        Currency(
            symbol: "RON",
            name: "Romanian Leu",
            code: "RON"
        ),
        Currency(
            symbol: "₪",
            name: "Israeli New Sheqel",
            code: "ILS"
        ),
        Currency(
            symbol: "ZWL$",
            name: "Zimbabwean Dollar",
            code: "ZWL"
        ),
        Currency(
            symbol: "Bs.F.",
            name: "Venezuelan Bolívar",
            code: "VEF"
        ),
        Currency(
            symbol: "Tk",
            name: "Bangladeshi Taka",
            code: "BDT"
        ),
        Currency(
            symbol: "MURs",
            name: "Mauritian Rupee",
            code: "MUR"
        ),
        Currency(
            symbol: "CO$",
            name: "Colombian Peso",
            code: "COP"
        ),
        Currency(
            symbol: "SR",
            name: "Saudi Riyal",
            code: "SAR"
        ),
        Currency(
            symbol: "₸",
            name: "Kazakhstani Tenge",
            code: "KZT"
        ),
        Currency(
            symbol: "RM",
            name: "Malaysian Ringgit",
            code: "MYR"
        ),
        Currency(
            symbol: "TSh",
            name: "Tanzanian Shilling",
            code: "TZS"
        ),
        Currency(
            symbol: "CN¥",
            name: "Chinese Yuan",
            code: "CNY"
        ),
        Currency(
            symbol: "CDF",
            name: "Congolese Franc",
            code: "CDF"
        ),
        Currency(
            symbol: "MOP$",
            name: "Macanese Pataca",
            code: "MOP"
        ),
        Currency(
            symbol: "MAD",
            name: "Moroccan Dirham",
            code: "MAD"
        ),
        Currency(
            symbol: "R",
            name: "South African Rand",
            code: "ZAR"
        ),
        Currency(
            symbol: "SDG",
            name: "Sudanese Pound",
            code: "SDG"
        )
    ]
    
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
    
    static func getWindowSize() -> CGSize {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return .zero }
        guard let size = windowScene.keyWindow?.frame.size else { return .zero }
        return size
    }
    
    /// Used in getCurrency to prevent multiple search in array
    static private var lastFoundCurrency: Currency?
    static func getCurrency(for code: String) async -> Currency? {
        guard lastFoundCurrency?.code != code else { return lastFoundCurrency }
        let currency = currencies.first { $0.code == code }
        lastFoundCurrency = currency
        return currency
    }
    
    nonisolated private static func getIconNames() -> [String] {
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
