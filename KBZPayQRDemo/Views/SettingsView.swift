import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: PaymentSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Toggle("Use Demo Mode", isOn: $settings.useDemoMode)
                }

                Section("Backend") {
                    TextField("https://api.yourdomain.com", text: $settings.backendBaseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    TextField("com.example.KBZPayQRDemo", text: $settings.appScheme)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("Expected endpoints: POST /payments/kbzpay/qr, GET /payments/kbzpay/qr/{orderId}/status, and POST /payments/kbzpay/app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Backend Response") {
                    Text("""
                    {
                      "id": "local-payment-id",
                      "merchantOrderId": "ORDER-123",
                      "prepayId": "kbz-prepay-id",
                      "qrContent": "KBZPay QR string",
                      "expiresAt": "2026-05-23T10:30:00Z"
                    }
                    """)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                }

                Section("App Pay Response") {
                    Text("""
                    {
                      "merchantOrderId": "ORDER-123",
                      "orderInfo": "appid=...&merch_code=...&nonce_str=...&prepay_id=...&timestamp=...",
                      "sign": "SERVER_GENERATED_SHA256",
                      "signType": "SHA256"
                    }
                    """)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
