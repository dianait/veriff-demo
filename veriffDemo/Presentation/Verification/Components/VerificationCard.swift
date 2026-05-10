import SwiftUI

struct VerificationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let state: VerificationState
    let action: () -> Void
    
    private var buttonTitle: String {
        switch state {
        case .loading: return "Starting…"
        case .completed, .cancelled, .failed: return "Try again"
        case .idle: return "Start verification"
        }
    }

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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.18), radius: colorScheme == .dark ? 12 : 20, y: 6)
        )
        .padding(.horizontal, 24)
    }
}
