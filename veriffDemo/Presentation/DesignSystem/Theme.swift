import SwiftUI

enum Theme {
    enum Colors {
        static let brand = Color("Brand")
        static let background = Color("Background")
        static let cardSurface = Color("CardSurface")
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
