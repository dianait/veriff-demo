import SwiftUI

struct VerificationView: View {
    let viewModel: VerificationViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VerificationCard(
                state: viewModel.state,
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
