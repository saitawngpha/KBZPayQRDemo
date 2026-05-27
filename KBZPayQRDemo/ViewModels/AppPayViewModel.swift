import Foundation

@MainActor
final class AppPayViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case creating
        case opening(orderId: String)
        case waiting(orderId: String)
        case paid(orderId: String?)
        case failed(String)
    }

    @Published var amountText = "25000"
    @Published var descriptionText = "Order payment"
    @Published private(set) var state: State = .idle

    private let settings: PaymentSettings
    private let appPayService = KBZPayAppPayService()
    private var demoCompletionTask: Task<Void, Never>?

    init(settings: PaymentSettings) {
        self.settings = settings
    }

    func startPayment() {
        demoCompletionTask?.cancel()

        guard let amount = Decimal(string: amountText), amount > 0 else {
            state = .failed("Enter a valid amount.")
            return
        }

        Task {
            do {
                state = .creating

                let orderId = "APP-\(Int(Date().timeIntervalSince1970))"
                let client: KBZPayAppAPIClient = settings.useDemoMode
                    ? DemoKBZPayAppAPIClient()
                    : try LiveKBZPayAppAPIClient(baseURLString: settings.backendBaseURL)

                let payment = try await client.createAppPayment(
                    amount: amount,
                    orderId: orderId,
                    description: descriptionText
                )

                state = .opening(orderId: payment.merchantOrderId)

                if settings.useDemoMode {
                    state = .waiting(orderId: payment.merchantOrderId)
                    completeDemoPayment(orderId: payment.merchantOrderId)
                } else {
                    try appPayService.startPayment(payment, appScheme: settings.appScheme)
                    state = .waiting(orderId: payment.merchantOrderId)
                }
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func handleCallback(url: URL) {
        guard let callback = appPayService.parseCallback(url: url) else {
            return
        }

        if callback.isSuccess {
            state = .paid(orderId: callback.orderId)
        } else {
            state = .failed("KBZPay returned result code \(callback.resultCode).")
        }
    }

    func reset() {
        demoCompletionTask?.cancel()
        state = .idle
    }

    private func completeDemoPayment(orderId: String) {
        demoCompletionTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            state = .paid(orderId: orderId)
        }
    }
}
