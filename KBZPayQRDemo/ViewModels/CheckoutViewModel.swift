import SwiftUI

@MainActor
final class CheckoutViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case creating
        case waiting(KBZPayQRPayment)
        case paid(orderId: String)
        case failed(String)
        case expired
    }

    @Published var amountText = "25000"
    @Published var descriptionText = "Order payment"
    @Published private(set) var state: State = .idle
    @Published private(set) var qrImage: UIImage?

    private let settings: PaymentSettings
    private var pollingTask: Task<Void, Never>?
    private var apiClient: KBZPayQRAPIClient {
        get throws {
            if settings.useDemoMode {
                return DemoKBZPayQRAPIClient()
            }

            return try LiveKBZPayQRAPIClient(baseURLString: settings.backendBaseURL)
        }
    }

    init(settings: PaymentSettings) {
        self.settings = settings
    }

    func createPayment() {
        pollingTask?.cancel()
        qrImage = nil

        guard let amount = Decimal(string: amountText), amount > 0 else {
            state = .failed("Enter a valid amount.")
            return
        }

        Task {
            do {
                state = .creating

                let orderId = "ORDER-\(Int(Date().timeIntervalSince1970))"
                let client = try apiClient
                let payment = try await client.createQRPayment(
                    amount: amount,
                    orderId: orderId,
                    description: descriptionText
                )

                qrImage = QRCodeGenerator.image(from: payment.qrContent)
                state = .waiting(payment)
                startPolling(orderId: payment.merchantOrderId, client: client)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func reset() {
        pollingTask?.cancel()
        qrImage = nil
        state = .idle
    }

    func cancelPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func startPolling(orderId: String, client: KBZPayQRAPIClient) {
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    let status = try await client.getPaymentStatus(orderId: orderId)

                    switch status {
                    case .pending:
                        continue
                    case .paid:
                        state = .paid(orderId: orderId)
                        cancelPolling()
                    case .failed:
                        state = .failed("KBZPay payment failed.")
                        cancelPolling()
                    case .expired:
                        state = .expired
                        cancelPolling()
                    }
                } catch is CancellationError {
                    return
                } catch {
                    state = .failed(error.localizedDescription)
                    cancelPolling()
                }
            }
        }
    }
}
