# veriffDemo

Demo iOS app showing how to integrate the [Veriff iOS SDK](https://github.com/Veriff/veriff-ios-spm) with Clean Architecture, SOLID principles, and modern SwiftUI.

A single screen creates a verification session and launches the Veriff flow. Session creation is mocked — the real production path is documented in `SessionRepository.swift`.

## Architecture

Clean Architecture in three layers plus an App composition root:

```
Presentation  ──►  Domain  ◄──  Data
                     ▲
                     └──  App (DependencyContainer)
```

- **Domain** — pure business types and protocols. No framework imports beyond `Foundation`.
- **Data** — adapters: only this layer imports `Veriff`. Implements Domain protocols.
- **Presentation** — SwiftUI views and observable view models. Depends on Domain protocols only.
- **App** — composition root: builds the dependency graph and exposes the entry point.

## Folder layout

```
veriffDemo/
├── App/
│   ├── DependencyContainer.swift     # wires the dependency graph
│   └── veriffDemoApp.swift           # @main entry point
├── Domain/                           # zero framework imports beyond Foundation
│   ├── Entities/
│   │   ├── VerificationResult.swift     # completed / cancelled / failed
│   │   └── VerificationSession.swift    # id + url returned by the session API
│   ├── Errors/VerificationError.swift
│   ├── Repositories/
│   │   ├── SessionRepositoryProtocol.swift
│   │   └── VerificationServiceProtocol.swift
│   └── UseCases/
│       ├── CreateVerificationSessionUseCase.swift
│       └── StartVerificationUseCase.swift
├── Data/                             # only layer that knows about Veriff
│   ├── Mappers/VeriffResultMapper.swift          # VeriffSdk.Result → VerificationResult
│   ├── Repositories/SessionRepository.swift      # demo impl + commented production reference
│   └── Services/VeriffVerificationService.swift  # wraps the SDK delegate as async
└── Presentation/
    ├── DesignSystem/
    │   ├── Theme.swift                  # brand colors, metrics
    │   └── PrimaryButtonStyle.swift
    └── Verification/
        ├── VerificationState.swift      # idle / loading / completed / cancelled / failed
        ├── VerificationView.swift       # reactive UI
        └── VerificationViewModel.swift  # @Observable, consumes use case protocols
```

## End-to-end flow

```
VerificationView (button tap)
  └─ VerificationViewModel.startVerification()
       ├─ CreateVerificationSessionUseCase.execute()         # Domain
       │    └─ SessionRepository.createSession()              # Data — hardcoded URL today
       │         └─ returns VerificationSession(id, url)
       └─ StartVerificationUseCase.execute(session:)         # Domain
            └─ VeriffVerificationService.start(session:)     # Data
                 ├─ VeriffSdk.startAuthentication(sessionUrl:)
                 └─ delegate → VeriffResultMapper → VerificationResult
       => state = .completed | .cancelled | .failed
```

## Where session creation should actually live

`SessionRepository.createSession()` currently returns a hardcoded session URL. **An iOS app should never call Veriff's `POST /v1/sessions` directly in production.** The recommended architecture is:

1. The iOS app calls **your own backend**, authenticated as the end-user.
2. Your backend calls Veriff's `POST /v1/sessions` with the private `X-AUTH-CLIENT` API key.
3. Your backend returns the resulting `verification.url` to the app.
4. The app passes that URL to the Veriff SDK.

Why:
- The Veriff API key never ships in the mobile binary (binaries are inspectable).
- The session is bound to your authenticated user.
- You can apply rate limiting, fraud signals, and analytics.
- You persist the user ↔ Veriff session mapping for webhooks.

A pseudo-code reference of `BackendSessionRepository` is included as a commented block in `Data/Repositories/SessionRepository.swift`. Because the protocol lives in Domain, swapping the implementation does not touch any other layer.

## Design notes

- **DIP** — Presentation depends on use case protocols, not concrete classes. Use cases depend on repository protocols. Repositories live in Data; their protocols live in Domain.
- **SRP** — every file has one job: the mapper translates, the repository fetches, the service runs the SDK, the view model coordinates UI.
- **Dependency rule** — only Data imports `Veriff`. Domain has zero framework dependencies. Presentation has no knowledge of how the session URL is obtained.
- **Concurrency** — built against Swift 6.2 with `-default-isolation=MainActor`. Types that flow across actor boundaries are explicitly `nonisolated`. The SDK service is `@MainActor` because the SDK presents UI; the delegate is bridged with `withCheckedContinuation` so the call site is plain `async`.
- **State surface** — `VerificationState` is the single source of truth for the UI; the View renders purely as a function of it.

## Previews

`VerificationView` ships five SwiftUI previews, one per state, using `#if DEBUG` mocks defined alongside the view model:

- Idle
- Loading
- Completed
- Cancelled
- Failed

Open `VerificationView.swift` and toggle the canvas (⌥⌘↩). Previews require a Simulator destination — they cannot launch on a physical device.

## Requirements

- Xcode 16 or newer (the project uses synchronized folder groups).
- iOS 17 or newer (uses `@Observable`).
- The Veriff SDK is added via Swift Package Manager (`https://github.com/Veriff/veriff-ios-spm`).

## Running

1. Open `veriffDemo.xcodeproj`.
2. Select an iOS Simulator destination.
3. Build and run.

The hardcoded demo session URL is a JWT with a finite expiry. When it expires, replace the constant in `DependencyContainer.swift` or generate a new one via Veriff's `POST /v1/sessions`.

## Possible next steps

- Add a unit test target — every layer is mockable through its protocol.
- Replace `SessionRepository` with a `BackendSessionRepository` once the backend endpoint exists.
- Move the demo URL out of source code (Info.plist, `.xcconfig`, or remote config).
