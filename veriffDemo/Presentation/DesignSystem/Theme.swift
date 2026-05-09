import SwiftUI

enum Theme {
    enum Colors {
        static let brand = Color(red: 0.03, green: 0.38, blue: 0.34)
        static let background = Color(red: 0.96, green: 0.98, blue: 0.97)
        static let cardSurface = Color.white
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
