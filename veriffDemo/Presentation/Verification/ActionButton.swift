import SwiftUI

struct ActionButton: View {
    let state: VerificationState
    let title: String
    let action: () -> Void
    
    private var buttonTitle: String {
        switch state {
        case .loading: return "Starting…"
        case .completed, .cancelled, .failed: return "Try again"
        case .idle: return "Start verification"
        }
    }

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
