import Foundation

struct KBZPayQRPayment: Decodable, Identifiable, Equatable {
    let id: String
    let merchantOrderId: String
    let prepayId: String?
    let qrContent: String
    let expiresAt: Date?
}

enum KBZPayQRStatus: String, Decodable, Equatable {
    case pending
    case paid
    case failed
    case expired
}

struct CreateQRPaymentRequest: Encodable {
    let amount: String
    let orderId: String
    let description: String
}

struct PaymentStatusResponse: Decodable {
    let status: KBZPayQRStatus
}
