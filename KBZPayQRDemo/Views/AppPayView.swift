import SwiftUI

struct AppPayView: View {
    @ObservedObject var settings: PaymentSettings
    @ObservedObject var viewModel: AppPayViewModel
    @State private var showingSettings = false

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
            .navigationTitle("KBZPay App Pay")
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "iphone.and.arrow.forward")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("SDK App Payment")
                        .font(.title2.bold())
                    Text(settings.useDemoMode ? "Demo mode is active" : "Opens the KBZPay app")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("Create a signed prepay order on your backend, then hand orderInfo and sign to the KBZPay iOS SDK.")
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
                viewModel.startPayment()
            } label: {
                Label("Pay in KBZPay App", systemImage: "arrow.up.forward.app")
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
            AppPayStatePanel(
                icon: "app.badge",
                color: .blue,
                title: "Ready for App Pay",
                message: "Tap the payment button to create a KBZPay prepay order."
            )

        case .creating:
            AppPayProgressPanel(title: "Creating payment")

        case .opening(let orderId):
            AppPayProgressPanel(title: "Opening KBZPay for \(orderId)")

        case .waiting(let orderId):
            AppPayStatePanel(
                icon: "clock.arrow.circlepath",
                color: .orange,
                title: "Waiting for Callback",
                message: "Order \(orderId) has been sent to KBZPay."
            )

        case .paid(let orderId):
            AppPayResultPanel(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "Payment Successful",
                message: "Order \(orderId ?? "-") is paid.",
                buttonTitle: "New Payment",
                action: viewModel.reset
            )

        case .failed(let message):
            AppPayResultPanel(
                icon: "xmark.octagon.fill",
                color: .red,
                title: "Payment Error",
                message: message,
                buttonTitle: "Try Again",
                action: viewModel.reset
            )
        }
    }

    private var backendNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Backend Contract", systemImage: "server.rack")
                .font(.headline)

            Text("Your backend should return merchantOrderId, orderInfo, sign, and signType from POST /payments/kbzpay/app. Keep the merchant key and SHA signing on the server.")
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

private struct AppPayStatePanel: View {
    let icon: String
    let color: Color
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)

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

private struct AppPayProgressPanel: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AppPayResultPanel: View {
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
