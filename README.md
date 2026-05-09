# veriffDemo

Demo iOS app showing how to integrate the [Veriff iOS SDK](https://github.com/Veriff/veriff-ios-spm) with Clean Architecture, SOLID principles, and modern SwiftUI.

A single screen creates a verification session against Veriff's `POST /v1/sessions` and immediately launches the SDK with the resulting URL. Every tap produces a fresh session — there is no hardcoded URL.

`HTTPSessionRepository` is the only `SessionRepositoryProtocol` implementation. It reads its config (API key + base URL) from a gitignored `Secrets.plist`. Without that file the app still launches but every verification attempt surfaces a clear "missing configuration" error in the UI, so the failure mode is discoverable instead of crashing.

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

Project root:

```
veriffDemo/                 # main app target (synced folder, see structure below)
veriffDemo.xcodeproj/
.gitignore
README.md
Secrets.example.plist       # template for the runtime config; copy into veriffDemo/ to enable HTTP impl
```

App target:

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
│   ├── Configuration/VeriffAPIConfig.swift       # loads API key + base URL from Secrets.plist
│   ├── DTOs/
│   │   ├── CreateSessionRequestDTO.swift         # POST /v1/sessions request body
│   │   └── CreateSessionResponseDTO.swift        # response shape
│   ├── Mappers/
│   │   ├── SessionMapper.swift                   # CreateSessionResponseDTO → VerificationSession
│   │   └── VeriffResultMapper.swift              # VeriffSdk.Result → VerificationResult
│   ├── Repositories/HTTPSessionRepository.swift  # POST /v1/sessions via URLSession
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
       ├─ CreateVerificationSessionUseCase.execute()              # Domain
       │    └─ HTTPSessionRepository.createSession()              # Data
       │         POST <baseURL>/v1/sessions
       │         headers:  Content-Type: application/json
       │                   X-AUTH-CLIENT: <api key from Secrets.plist>
       │         body:     { "verification": {} }
       │         response  → CreateSessionResponseDTO
       │                   → SessionMapper.toDomain
       │                   → VerificationSession(id, url)
       └─ StartVerificationUseCase.execute(session:)              # Domain
            └─ VeriffVerificationService.start(session:)          # Data
                 ├─ VeriffSdk.startAuthentication(sessionUrl:)
                 └─ delegate → VeriffResultMapper → VerificationResult
       => state = .completed | .cancelled | .failed
```

If `Secrets.plist` is missing or its `VeriffAPIKey` is empty, `DependencyContainer` falls back to an internal `UnconfiguredSessionRepository` that throws `VerificationError.missingConfiguration`. The ViewModel maps that error to a user-visible message asking the developer to configure the file.

## Configuration

The repo includes a `Secrets.example.plist` template at the project root. Setup steps:

1. If `veriffDemo/Secrets.plist` does not exist, copy `Secrets.example.plist` into `veriffDemo/` and rename it to `Secrets.plist`.
2. In Xcode (or any plist editor), set `VeriffAPIKey` to a real API key from your Veriff Customer Portal → API keys.
3. Leave `VeriffBaseURL` as `https://stationapi.veriff.com` unless you have a different endpoint.
4. Re-run the app.

How the config is loaded:

- `VeriffAPIConfig.loadFromBundle()` reads `Secrets.plist` from the app bundle, validates that both keys are present and `VeriffAPIKey` is non-empty, and returns a `VeriffAPIConfig`.
- `DependencyContainer.makeSessionRepository()` returns `HTTPSessionRepository(config:)` when the config loads. Otherwise it returns an internal `UnconfiguredSessionRepository` that surfaces a clear error on first use — the app launches either way, so missing setup is obvious instead of fatal.

`veriffDemo/Secrets.plist` is gitignored, so the key never enters version control.

### A note on doing this in production

The Veriff docs do not explicitly forbid calling `POST /v1/sessions` from a mobile app. It works for sandbox / personal exploration, but **in a real product it should not be done from the device.** The recommended architecture is:

1. The iOS app calls **your own backend**, authenticated as the end-user.
2. Your backend calls Veriff's `POST /v1/sessions` with the private `X-AUTH-CLIENT` API key.
3. Your backend returns the resulting `verification.url` to the app.
4. The app passes that URL to the Veriff SDK.

Why:

- The Veriff API key never ships in the mobile binary (binaries are inspectable).
- The session is bound to your authenticated user on your side.
- You can apply rate limiting, fraud signals, and analytics centrally.
- You persist the user ↔ Veriff session mapping for webhooks.

Because `SessionRepositoryProtocol` lives in Domain, replacing `HTTPSessionRepository` with a `BackendSessionRepository` is a one-line change in `DependencyContainer`. Nothing else in the app would change — that is the practical payoff of the layered architecture.

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
2. Configure `Secrets.plist` as described in **Configuration** above.
3. Select an iOS Simulator destination (Previews and the SDK do not run on physical devices via Previews).
4. Build and run.

Each tap of "Start verification" creates a fresh session via `POST /v1/sessions` and launches the Veriff SDK with the resulting URL.

## Possible next steps

- Add a unit test target — every layer is mockable through its protocol.
- Replace `HTTPSessionRepository` with a `BackendSessionRepository` once the backend endpoint exists.
