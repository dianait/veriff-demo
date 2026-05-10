import SwiftUI

enum Theme {
    enum Colors {
        static let brand = Color(.brand)
        static let background = Color(.background)
        static let cardSurface = Color(.cardSurface)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }

    enum Metrics {
        static let cardCornerRadius: CGFloat = 28
        static let buttonCornerRadius: CGFloat = 14
        static let cardPadding: CGFloat = 24
    }
}
