import SwiftUI

struct StatusBanner: View {
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
