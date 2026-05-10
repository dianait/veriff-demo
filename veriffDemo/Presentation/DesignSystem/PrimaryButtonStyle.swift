import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration)
    }

    private struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.brand)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.buttonCornerRadius))
                .opacity(configuration.isPressed ? 0.85 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}
