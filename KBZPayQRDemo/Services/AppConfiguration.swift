import Foundation

enum AppConfiguration {
    static let demoQRContent = "KBZPAY-DEMO|merchant=DEMO_MERCHANT|amount=25000|order=DEMO-ORDER"
}

final class PaymentSettings: ObservableObject {
    @Published var useDemoMode: Bool {
        didSet { UserDefaults.standard.set(useDemoMode, forKey: Self.useDemoModeKey) }
    }

    @Published var backendBaseURL: String {
        didSet { UserDefaults.standard.set(backendBaseURL, forKey: Self.backendBaseURLKey) }
    }

    @Published var appScheme: String {
        didSet { UserDefaults.standard.set(appScheme, forKey: Self.appSchemeKey) }
    }

    private static let useDemoModeKey = "kbzpay.demoMode"
    private static let backendBaseURLKey = "kbzpay.backendBaseURL"
    private static let appSchemeKey = "kbzpay.appScheme"

    init() {
        let savedURL = UserDefaults.standard.string(forKey: Self.backendBaseURLKey) ?? ""
        let savedScheme = UserDefaults.standard.string(forKey: Self.appSchemeKey) ?? "com.example.KBZPayQRDemo"
        backendBaseURL = savedURL
        appScheme = savedScheme
        useDemoMode = UserDefaults.standard.object(forKey: Self.useDemoModeKey) as? Bool ?? true
    }
}
