import Foundation

protocol KBZPayQRAPIClient {
    func createQRPayment(amount: Decimal, orderId: String, description: String) async throws -> KBZPayQRPayment
    func getPaymentStatus(orderId: String) async throws -> KBZPayQRStatus
}

enum KBZPayAPIError: LocalizedError {
    case invalidBackendURL
    case invalidResponse
    case serverStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBackendURL:
            return "Enter a valid backend URL in Settings."
        case .invalidResponse:
            return "The payment server returned an invalid response."
        case .serverStatus(let code):
            return "The payment server returned HTTP \(code)."
        }
    }
}

final class LiveKBZPayQRAPIClient: KBZPayQRAPIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURLString: String, session: URLSession = .shared) throws {
        let trimmed = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed), let scheme = url.scheme, scheme.hasPrefix("http") else {
            throw KBZPayAPIError.invalidBackendURL
        }

        baseURL = url
        self.session = session
    }

    func createQRPayment(amount: Decimal, orderId: String, description: String) async throws -> KBZPayQRPayment {
        var request = URLRequest(url: baseURL.appendingPathComponent("payments/kbzpay/qr"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            CreateQRPaymentRequest(
                amount: NSDecimalNumber(decimal: amount).stringValue,
                orderId: orderId,
                description: description
            )
        )

        let data = try await perform(request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(KBZPayQRPayment.self, from: data)
    }

    func getPaymentStatus(orderId: String) async throws -> KBZPayQRStatus {
        let request = URLRequest(url: baseURL.appendingPathComponent("payments/kbzpay/qr/\(orderId)/status"))
        let data = try await perform(request)
        return try JSONDecoder().decode(PaymentStatusResponse.self, from: data).status
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KBZPayAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw KBZPayAPIError.serverStatus(httpResponse.statusCode)
        }

        return data
    }
}

final class DemoKBZPayQRAPIClient: KBZPayQRAPIClient {
    private var checks = 0

    func createQRPayment(amount: Decimal, orderId: String, description: String) async throws -> KBZPayQRPayment {
        try await Task.sleep(nanoseconds: 600_000_000)

        let amountText = NSDecimalNumber(decimal: amount).stringValue
        let qrContent = "KBZPAY-DEMO|merchant=DEMO_MERCHANT|amount=\(amountText)|order=\(orderId)"

        return KBZPayQRPayment(
            id: UUID().uuidString,
            merchantOrderId: orderId,
            prepayId: "DEMO-PREPAY-\(orderId.prefix(8))",
            qrContent: qrContent,
            expiresAt: Date().addingTimeInterval(180)
        )
    }

    func getPaymentStatus(orderId: String) async throws -> KBZPayQRStatus {
        checks += 1
        try await Task.sleep(nanoseconds: 200_000_000)
        return checks >= 5 ? .paid : .pending
    }
}
