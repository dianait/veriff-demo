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
## Design notes

- **DIP** — Presentation depends on `VerificationProviderProtocol` (Domain), not concrete types. The provider lives in Data and resolves its own dependencies (the session repository) internally.
- **SRP** — every file has one job: the mapper translates, the repository fetches, the provider orchestrates the SDK, the view model coordinates UI. The verification screen is split into `VerificationHeader`, `StatusBanner`, and `ActionButton`, each rendered as a function of the current `VerificationState`.
- **Dependency rule** — only Data imports `Veriff`. Domain has zero framework dependencies. Presentation has no knowledge of how the session URL is obtained or which SDK runs the flow.
- **Concurrency** — built against Swift 6.2 with `-default-isolation=MainActor`. Types that flow across actor boundaries (`VerificationResult`, `VerificationError`, `VerificationSession`, `SessionRepositoryProtocol`) are explicitly `nonisolated`. The provider is `@MainActor` because the SDK presents UI; its delegate is bridged with `withCheckedContinuation` so the call site is plain `async`.
- **State surface** — `VerificationState` is the single source of truth for the UI, and `VerificationResult` exposes a `.state` extension so the view model never has to switch on the domain enum.
- **Accessibility** — VoiceOver labels and hints on the CTA, combined accessibility elements on the banner, the logo respects Dynamic Type, and the screen honors Reduce Motion. Card shadows are tuned per color scheme for contrast in dark mode.