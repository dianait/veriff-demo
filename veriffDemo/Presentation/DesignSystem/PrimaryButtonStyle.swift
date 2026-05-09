import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.Colors.brand)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.buttonCornerRadius))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
