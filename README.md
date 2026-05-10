# veriffDemo


![Veriff iOS SDK](./public/veriff-demo.gif)

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
- **Data** — adapters: only this layer imports `Veriff`. Implements the Domain provider protocol and owns its own data sources.
- **Presentation** — SwiftUI views and observable view models. Depends on the Domain provider protocol only.
- **App** — composition root: builds the dependency graph and exposes the entry point.

The app exposes a single Domain seam — `VerificationProviderProtocol` — that the view model consumes. The provider lives in Data and orchestrates session creation + SDK launch internally; the view model has no notion of HTTP, DTOs, or the Veriff SDK.

## Folder layout

Project root:

```
veriffDemo/                 # main app target (synced folder, see structure below)
veriffDemo.xcodeproj/
veriffDemoTests/            # Swift Testing unit tests
veriffDemoUITests/
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
│   │   └── VerificationResult.swift     # completed / cancelled / failed
│   ├── Errors/VerificationError.swift
│   └── Services/
│       └── VerificationProviderProtocol.swift
├── Data/                             # only layer that knows about Veriff
│   ├── Configuration/VeriffAPIConfig.swift       # loads API key + base URL from Secrets.plist
│   ├── DTOs/
│   │   ├── CreateSessionRequestDTO.swift         # POST /v1/sessions request body
│   │   └── CreateSessionResponseDTO.swift        # response shape
│   ├── Mappers/
│   │   ├── SessionMapper.swift                   # CreateSessionResponseDTO → VerificationSession
│   │   └── VeriffResultMapper.swift              # VeriffSdk.Result → VerificationResult
│   ├── Models/
│   │   └── VerificationSession.swift             # id + url returned by the session API
│   ├── Providers/
│   │   └── VeriffVerificationProvider.swift      # orchestrates session + SDK behind the Domain protocol
│   └── Repositories/
│       ├── SessionRepositoryProtocol.swift       # Data-internal seam, used by the provider
│       └── HTTPSessionRepository.swift           # POST /v1/sessions via URLSession
└── Presentation/
    ├── DesignSystem/
    │   ├── Theme.swift                  # brand colors, metrics
    │   └── PrimaryButtonStyle.swift
    └── Verification/
        ├── VerificationView.swift       # screen scaffold + previews
        ├── VerificationCard.swift       # card surface that hosts the flow
        ├── VerificationHeader.swift     # logo + copy
        ├── StatusBanner.swift           # success / cancelled / failed banner
        ├── ActionButton.swift           # primary CTA with loading state
        ├── VerificationState.swift      # idle / loading / completed / cancelled / failed (+ result→state mapping)
        └── VerificationViewModel.swift  # @Observable, consumes the Domain provider
```

## End-to-end flow

```
VerificationView (button tap)
  └─ VerificationViewModel.startVerification()
       └─ VerificationProviderProtocol.verify()                      # Domain seam
            └─ VeriffVerificationProvider.verify()                   # Data
                 ├─ SessionRepositoryProtocol.createSession()
                 │    └─ HTTPSessionRepository.createSession()
                 │         POST <baseURL>/v1/sessions
                 │         headers:  Content-Type: application/json
                 │                   X-AUTH-CLIENT: <api key from Secrets.plist>
                 │         body:     { "verification": {} }
                 │         response  → CreateSessionResponseDTO
                 │                   → SessionMapper.toDomain
                 │                   → VerificationSession(id, url)
                 └─ VeriffSdk.startAuthentication(sessionUrl:)
                      delegate → VeriffResultMapper → VerificationResult
       => VerificationResult.state =
            .completed | .cancelled | .failed(message)
```

If `Secrets.plist` is missing or its `VeriffAPIKey` is empty, `DependencyContainer` falls back to an internal `UnconfiguredSessionRepository` that throws `VerificationError.missingConfiguration`. The provider wraps any thrown `VerificationError` into `.failed`, which the view model maps to a user-visible message asking the developer to configure the file.

The provider also rejects overlapping starts: if `verify()` is invoked while another verification is in flight, it returns `.failed(.unknown(...))` immediately instead of leaking a continuation.

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

Because the only seam Presentation depends on is `VerificationProviderProtocol`, swapping `HTTPSessionRepository` for a `BackendSessionRepository` is a one-line change inside `DependencyContainer`. Nothing in Presentation or Domain changes — that is the practical payoff of the layered architecture.

## Design notes

- **DIP** — Presentation depends on `VerificationProviderProtocol` (Domain), not concrete types. The provider lives in Data and resolves its own dependencies (the session repository) internally.
- **SRP** — every file has one job: the mapper translates, the repository fetches, the provider orchestrates the SDK, the view model coordinates UI. The verification screen is split into `VerificationHeader`, `StatusBanner`, and `ActionButton`, each rendered as a function of the current `VerificationState`.
- **Dependency rule** — only Data imports `Veriff`. Domain has zero framework dependencies. Presentation has no knowledge of how the session URL is obtained or which SDK runs the flow.
- **Concurrency** — built against Swift 6.2 with `-default-isolation=MainActor`. Types that flow across actor boundaries (`VerificationResult`, `VerificationError`, `VerificationSession`, `SessionRepositoryProtocol`) are explicitly `nonisolated`. The provider is `@MainActor` because the SDK presents UI; its delegate is bridged with `withCheckedContinuation` so the call site is plain `async`.
- **State surface** — `VerificationState` is the single source of truth for the UI, and `VerificationResult` exposes a `.state` extension so the view model never has to switch on the domain enum.
- **Accessibility** — VoiceOver labels and hints on the CTA, combined accessibility elements on the banner, the logo respects Dynamic Type, and the screen honors Reduce Motion. Card shadows are tuned per color scheme for contrast in dark mode.

## Previews

`VerificationView` ships five SwiftUI previews, one per state, using `#if DEBUG` mocks defined alongside the view model:

- Idle
- Loading
- Completed
- Cancelled
- Failed

Open `VerificationView.swift` and toggle the canvas (⌥⌘↩). Previews require a Simulator destination — they cannot launch on a physical device.

## Tests

Unit tests live under `veriffDemoTests/` and use [Swift Testing](https://developer.apple.com/xcode/swift-testing/):

- `VerificationViewModelTests` — drives the view model with stub and suspending providers to assert the `VerificationResult` → `VerificationState` mapping (including all `VerificationError` cases as a parameterized test) and that `.loading` is observable while a verification is in flight.
- `SessionMapperTests` — covers the happy path (`CreateSessionResponseDTO` → `VerificationSession`) and the empty-URL guard that throws `VerificationError.invalidSession`.

A `veriffDemoUITests/` target is included for launch and smoke UI tests.

Run the suites from Xcode with ⌘U.

## Requirements

- Xcode 16 or newer (the project uses synchronized folder groups).
- iOS 17 or newer (uses `@Observable`).
- Swift 6.2 toolchain (the project enables `-default-isolation=MainActor`).
- The Veriff SDK is added via Swift Package Manager (`https://github.com/Veriff/veriff-ios-spm`).

## Running

1. Open `veriffDemo.xcodeproj`.
2. Configure `Secrets.plist` as described in **Configuration** above.
3. Select an iOS Simulator destination (Previews and the SDK do not run on physical devices via Previews).
4. Build and run.

Each tap of "Start verification" creates a fresh session via `POST /v1/sessions` and launches the Veriff SDK with the resulting URL.

## Possible next steps

- Replace `HTTPSessionRepository` with a `BackendSessionRepository` once the backend endpoint exists.
- Expand UI tests beyond the launch smoke test (drive the SDK with a fake provider injected via launch arguments).
