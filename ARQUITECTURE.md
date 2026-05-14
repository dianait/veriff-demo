## Architecture

Clean Architecture in three layers plus an App composition root:

```
Presentation  ──►  Domain  ◄──  Data
                     ▲
                     └──  App (DependencyContainer)
```

- **Domain** — pure business types and protocols. No framework imports beyond `Foundation`.
- **Data** — adapters: only this layer imports `Veriff`. Implements the Domain provider protocol and owns its own repositories and data sources.
- **Presentation** — SwiftUI views and observable view models. Depends on the Domain provider protocol only.
- **App** — composition root: builds the dependency graph and exposes the entry point.

The app exposes a single Domain seam — `VerificationProviderProtocol` — that the view model consumes. The provider lives in Data and orchestrates session retrieval + SDK launch internally; the view model has no notion of HTTP, DTOs, caching, or the Veriff SDK.

Inside Data, the `SessionRepository` is a coordinator that sits on top of two data sources — a remote one (HTTP) and a local one (Keychain) — and decides when to return a cached session vs. fetch a fresh one. The provider only talks to the repository.

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
│   │   └── VerificationSession.swift             # id + url + createdAt; knows when it has expired
│   ├── DataSources/
│   │   ├── SessionRemoteDataSourceProtocol.swift     # remote seam (createSession)
│   │   ├── HTTPSessionRemoteDataSource.swift         # POST /v1/sessions via URLSession
│   │   ├── SessionLocalDataSourceProtocol.swift      # local cache seam (load / save / clear)
│   │   └── KeychainSessionLocalDataSource.swift      # Keychain-backed session cache
│   ├── Repositories/
│   │   ├── SessionRepositoryProtocol.swift       # Data-internal seam, used by the provider
│   │   └── SessionRepository.swift               # coordinates remote + local with a TTL
│   └── Providers/
│       └── VeriffVerificationProvider.swift      # orchestrates session + SDK behind the Domain protocol
└── Presentation/
    ├── DesignSystem/
    │   ├── Theme.swift                  # brand colors, metrics
    │   └── PrimaryButtonStyle.swift
    └── Verification/
        ├── VerificationView.swift              # screen scaffold + previews
        ├── VerificationState.swift             # idle / loading / completed / cancelled / failed (+ result→state mapping)
        ├── VerificationViewModel.swift         # @Observable, consumes the Domain provider
        └── Components/
            ├── VerificationCard.swift          # card surface that hosts the flow
            ├── VerificationHeader.swift        # logo + copy
            ├── StatusBanner.swift              # success / cancelled / failed banner
            └── ActionButton.swift              # primary CTA with loading state
```
## Design notes

- **DIP** — Presentation depends on `VerificationProviderProtocol` (Domain), not concrete types. The provider lives in Data and resolves its own dependencies (the session repository) internally. The repository in turn depends on remote and local data-source protocols, not on `URLSession` or `Keychain` directly.
- **SRP** — every file has one job: data sources fetch or persist, the repository coordinates them and applies the cache policy, the mapper translates, the provider orchestrates the SDK, the view model coordinates UI. The verification screen is split into `VerificationHeader`, `StatusBanner`, and `ActionButton`, each rendered as a function of the current `VerificationState`.
- **Dependency rule** — only Data imports `Veriff` and `Security`. Domain has zero framework dependencies. Presentation has no knowledge of how the session URL is obtained, where it is cached, or which SDK runs the flow.
- **Session caching** — `VerificationSession` carries a `createdAt` timestamp and a `maxLifetime` of 7 days (Veriff's contract). `SessionRepository` returns the cached session from the Keychain when it is still valid, fetches a fresh one otherwise, and the provider asks the repository to `invalidate()` on terminal failures so the next attempt re-fetches.
- **Concurrency** — built against Swift 6.2 with `-default-isolation=MainActor`. Types that flow across actor boundaries (`VerificationResult`, `VerificationError`, `VerificationSession`, `SessionRepositoryProtocol`, both data-source protocols) are explicitly `nonisolated`. The provider is `@MainActor` because the SDK presents UI; its delegate is bridged with `withCheckedContinuation` so the call site is plain `async`. Overlapping `verify()` calls are rejected up front to avoid leaking continuations.
- **State surface** — `VerificationState` is the single source of truth for the UI, and `VerificationResult` exposes a `.state` extension so the view model never has to switch on the domain enum.
- **Testing** — Swift Testing covers the mapper and the view model. The view model tests use an in-target stub provider plus a suspending actor-based provider to assert the `.loading` state is exposed while verification is in flight.
- **Accessibility** — VoiceOver labels and hints on the CTA, combined accessibility elements on the banner, the logo respects Dynamic Type, and the screen honors Reduce Motion. Card shadows are tuned per color scheme for contrast in dark mode.