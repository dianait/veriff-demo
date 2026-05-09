import SwiftUI

@main
struct veriffDemoApp: App {
    @State private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            VerificationView(viewModel: container.makeVerificationViewModel())
        }
    }
}
