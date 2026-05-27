import Foundation
import KBZPayAPPPay
import UIKit

protocol KBZPayAppPayServicing {
    func isKBZPayInstalled() -> Bool
    func startPayment(_ payment: KBZPayAppPayment, appScheme: String) throws
    func parseCallback(url: URL) -> KBZPayAppCallback?
}

enum KBZPayAppPayError: LocalizedError {
    case appNotInstalled

    var errorDescription: String? {
        switch self {
        case .appNotInstalled:
            return "Please install KBZPay before starting app payment."
        }
    }
}

final class KBZPayAppPayService: KBZPayAppPayServicing {
    func isKBZPayInstalled() -> Bool {
        guard let url = URL(string: "kbzpay://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func startPayment(_ payment: KBZPayAppPayment, appScheme: String) throws {
        guard isKBZPayInstalled() else {
            throw KBZPayAppPayError.appNotInstalled
        }

        let controller = PaymentViewController()
        controller.startPay(
            withOrderInfo: payment.orderInfo,
            signType: payment.signType,
            sign: payment.sign,
            appScheme: appScheme
        )
    }

    func parseCallback(url: URL) -> KBZPayAppCallback? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let items = components.queryItems ?? []
        let result = items.first(where: { $0.name == "EXTRA_RESULT" })?.value
        let orderId = items.first(where: { $0.name == "EXTRA_ORDER_ID" })?.value

        guard let result else { return nil }
        return KBZPayAppCallback(resultCode: result, orderId: orderId)
    }
}

final class DemoKBZPayAppPayService: KBZPayAppPayServicing {
    func isKBZPayInstalled() -> Bool {
        true
    }

    func startPayment(_ payment: KBZPayAppPayment, appScheme: String) throws {
    }

    func parseCallback(url: URL) -> KBZPayAppCallback? {
        nil
    }
}
