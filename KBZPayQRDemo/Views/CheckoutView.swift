import SwiftUI

struct CheckoutView: View {
    @ObservedObject private var settings: PaymentSettings
    @StateObject private var viewModel: CheckoutViewModel
    @State private var showingSettings = false

    init(settings: PaymentSettings = PaymentSettings()) {
        self.settings = settings
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(settings: settings))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        paymentForm
                        paymentState
                        backendNote
                    }
                    .padding(20)
                }
            }
            .navigationTitle("KBZPay QR")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
            .onDisappear {
                viewModel.cancelPolling()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Merchant QR Checkout")
                        .font(.title2.bold())
                    Text(settings.useDemoMode ? "Demo mode is active" : "Connected to your backend")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("Generate a dynamic KBZPay QR code for the order, show it to the customer, then wait for your backend to confirm payment.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var paymentForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payment")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("25000", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Order payment", text: $viewModel.descriptionText)
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                viewModel.createPayment()
            } label: {
                Label("Generate QR", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isBusy)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var paymentState: some View {
        switch viewModel.state {
        case .idle:
            EmptyStatePanel(
                icon: "iphone.gen3",
                title: "Ready to Create QR",
                message: "Enter the amount and generate a QR when the customer is ready to pay."
            )

        case .creating:
            ProgressPanel(title: "Creating KBZPay QR")

        case .waiting(let payment):
            QRPaymentPanel(
                payment: payment,
                qrImage: viewModel.qrImage,
                onCancel: viewModel.reset
            )

        case .paid(let orderId):
            ResultPanel(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "Payment Successful",
                message: "Order \(orderId) is paid.",
                buttonTitle: "New Payment",
                action: viewModel.reset
            )

        case .failed(let message):
            ResultPanel(
                icon: "xmark.octagon.fill",
                color: .red,
                title: "Payment Error",
                message: message,
                buttonTitle: "Try Again",
                action: viewModel.reset
            )

        case .expired:
            ResultPanel(
                icon: "clock.badge.exclamationmark.fill",
                color: .orange,
                title: "QR Expired",
                message: "Generate a new QR code for this customer.",
                buttonTitle: "Generate New QR",
                action: viewModel.createPayment
            )
        }
    }

    private var backendNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Production Backend", systemImage: "lock.shield")
                .font(.headline)

            Text("Your iOS app should call your backend, not KBZPay directly. The backend keeps the merchant key, creates the QR pre-order, receives KBZPay notify callbacks, and exposes payment status to the app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var isBusy: Bool {
        if case .creating = viewModel.state {
            return true
        }
        return false
    }
}

private struct QRPaymentPanel: View {
    let payment: KBZPayQRPayment
    let qrImage: UIImage?
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Scan with KBZPay")
                    .font(.headline)

                Text(payment.merchantOrderId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 14, y: 6)

                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: 300)
            .aspectRatio(1, contentMode: .fit)

            if let expiresAt = payment.expiresAt {
                Text("Expires \(expiresAt.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ProgressView("Waiting for payment confirmation")
                .font(.footnote)

            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyStatePanel: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.red)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProgressPanel: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(title)
                .font(.headline)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ResultPanel: View {
    let icon: String
    let color: Color
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 46))
                .foregroundStyle(color)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(buttonTitle) {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CheckoutView()
}
