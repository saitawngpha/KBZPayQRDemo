import Foundation

struct KBZPayAppPayment: Decodable, Equatable {
    let merchantOrderId: String
    let orderInfo: String
    let sign: String
    let signType: String
}

struct KBZPayAppCallback: Equatable {
    let resultCode: String
    let orderId: String?

    var isSuccess: Bool {
        resultCode == "0"
    }
}
