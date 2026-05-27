import SwiftUI

struct PaymentHomeView: View {
    @StateObject private var settings: PaymentSettings
    @StateObject private var appPayViewModel: AppPayViewModel

    init() {
        let settings = PaymentSettings()
        _settings = StateObject(wrappedValue: settings)
        _appPayViewModel = StateObject(wrappedValue: AppPayViewModel(settings: settings))
    }

    var body: some View {
        TabView {
            CheckoutView(settings: settings)
                .tabItem {
                    Label("QR Pay", systemImage: "qrcode")
                }

            AppPayView(settings: settings, viewModel: appPayViewModel)
                .tabItem {
                    Label("App Pay", systemImage: "iphone.and.arrow.forward")
                }
        }
        .onOpenURL { url in
            appPayViewModel.handleCallback(url: url)
        }
    }
}
