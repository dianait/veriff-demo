import SwiftUI

struct VerificationView: View {
    let viewModel: VerificationViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VerificationCard(
                state: viewModel.state,
                buttonTitle: buttonTitle,
                action: { Task { await viewModel.startVerification() } }
            )
            Spacer()
            footer
        }
        .background(Theme.Colors.background)
    }

    private var footer: some View {
        Text("Powered by Veriff SDK")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .loading: return "Starting…"
        case .completed, .cancelled, .failed: return "Try again"
        case .idle: return "Start verification"
        }
    }
}

private struct VerificationCard: View {
    let state: VerificationState
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VerificationHeader()
            StatusBanner(state: state)
            ActionButton(state: state, title: buttonTitle, action: action)
        }
        .padding(Theme.Metrics.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius)
                .fill(Theme.Colors.cardSurface)
                .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
        )
        .padding(.horizontal, 24)
    }
}

private struct VerificationHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(.veriff)
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .accessibilityHidden(true)

            Text("DEMO")
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(1.5)
                .foregroundStyle(.secondary)

            Text("Verify your identity securely")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Start a sample verification flow using the Veriff iOS SDK.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

private struct ActionButton: View {
    let state: VerificationState
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if state == .loading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.shield.fill")
                }
                Text(title)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(state == .loading)
        .padding(.top, 8)
        .accessibilityLabel(title)
        .accessibilityHint("Starts identity verification with Veriff")
    }
}

private struct StatusBanner: View {
    let state: VerificationState

    var body: some View {
        switch state {
        case .idle, .loading:
            EmptyView()
        case .completed:
            label("Verification completed", color: Theme.Colors.success, icon: "checkmark.circle.fill")
        case .cancelled:
            label("Verification cancelled", color: Theme.Colors.warning, icon: "xmark.circle.fill")
        case .failed(let message):
            label(message, color: Theme.Colors.error, icon: "exclamationmark.triangle.fill")
        }
    }

    private func label(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.footnote)
        }
        .foregroundStyle(color)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

#Preview("Idle") {
    VerificationView(viewModel: .preview())
        .preferredColorScheme(.dark)
}

#Preview("Loading") {
    VerificationView(viewModel: .preview(state: .loading))
}

#Preview("Completed") {
    VerificationView(viewModel: .preview(state: .completed))
}

#Preview("Cancelled") {
    VerificationView(viewModel: .preview(state: .cancelled))
}

#Preview("Failed") {
    VerificationView(viewModel: .preview(state: .failed("Camera permission denied")))
}
