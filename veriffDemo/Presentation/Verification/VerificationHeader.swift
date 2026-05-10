import SwiftUI

struct VerificationHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(.veriff)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 160)
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
