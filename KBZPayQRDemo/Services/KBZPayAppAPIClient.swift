import Foundation

protocol KBZPayAppAPIClient {
    func createAppPayment(amount: Decimal, orderId: String, description: String) async throws -> KBZPayAppPayment
}

final class LiveKBZPayAppAPIClient: KBZPayAppAPIClient {
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

    func createAppPayment(amount: Decimal, orderId: String, description: String) async throws -> KBZPayAppPayment {
        var request = URLRequest(url: baseURL.appendingPathComponent("payments/kbzpay/app"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            CreateQRPaymentRequest(
                amount: NSDecimalNumber(decimal: amount).stringValue,
                orderId: orderId,
                description: description
            )
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KBZPayAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw KBZPayAPIError.serverStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(KBZPayAppPayment.self, from: data)
    }
}

final class DemoKBZPayAppAPIClient: KBZPayAppAPIClient {
    func createAppPayment(amount: Decimal, orderId: String, description: String) async throws -> KBZPayAppPayment {
        try await Task.sleep(nanoseconds: 500_000_000)

        return KBZPayAppPayment(
            merchantOrderId: orderId,
            orderInfo: "appid=DEMO_APP&merch_code=DEMO_MERCHANT&nonce_str=DEMO_NONCE&prepay_id=DEMO_PREPAY&timestamp=\(Int(Date().timeIntervalSince1970))",
            sign: "DEMO_SIGN",
            signType: "SHA256"
        )
    }
}
