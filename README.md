# veriffDemo

<table>
  <tr>
    <td width="65%">
      <p>
        Demo iOS app showing how to integrate the
        <a href="https://github.com/Veriff/veriff-ios-spm">Veriff iOS SDK</a>
        with Clean Architecture, SOLID principles, and modern SwiftUI.
      </p>
      <p>
        A single screen creates a verification session against Veriff's
        <code>POST /v1/sessions</code> and immediately launches the SDK with the resulting URL.
        Every tap produces a fresh session — there is no hardcoded URL.
      </p>
      <p>
        <code>HTTPSessionRepository</code> is the only
        <code>SessionRepositoryProtocol</code> implementation. It reads its config
        API key + base URL from a gitignored <code>Secrets.plist</code>.
        Without that file, the app still launches but every verification attempt
        surfaces a clear "missing configuration" error in the UI, so the failure
        mode is discoverable instead of crashing.
      </p>
    </td>
      <td width="35%">
      <img src="./public/veriff-demo.gif" alt="Veriff iOS demo app screenshot" width="260">
    </td>
  </tr>
</table>

## 💠 End-to-end flow

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

## ⚙️ Configuration

The repo includes a `Secrets.example.plist` template at the project root. Setup steps:

1. If `veriffDemo/Secrets.plist` does not exist, copy `Secrets.example.plist` into `veriffDemo/` and rename it to `Secrets.plist`.
2. In Xcode (or any plist editor), set `VeriffAPIKey` to a real API key from your Veriff Customer Portal → API keys.
3. Leave `VeriffBaseURL` as `https://stationapi.veriff.com` unless you have a different endpoint.
4. Re-run the app.

How the config is loaded:

- `VeriffAPIConfig.loadFromBundle()` reads `Secrets.plist` from the app bundle, validates that both keys are present and `VeriffAPIKey` is non-empty, and returns a `VeriffAPIConfig`.
- `DependencyContainer.makeSessionRepository()` returns `HTTPSessionRepository(config:)` when the config loads. Otherwise it returns an internal `UnconfiguredSessionRepository` that surfaces a clear error on first use — the app launches either way, so missing setup is obvious instead of fatal.

`veriffDemo/Secrets.plist` is gitignored, so the key never enters version control.

> [!CAUTION]
> This demo performs `POST /v1/sessions` directly from the device for sandbox and learning purposes only.
>
> In a real production environment, session creation should be delegated to a backend service to avoid exposing API credentials in the mobile binary.
> Why:
> - The Veriff API key never ships inside the mobile binary, since mobile applications are inherently inspectable.
> - The verification session remains associated with your authenticated user on your backend.
> - You can apply rate limiting, fraud detection, telemetry, and analytics centrally.
> - You can persist the user ↔ Veriff session mapping for webhook handling and auditing.

> [!TIP]
> Because the only seam Presentation depends on is `VerificationProviderProtocol`, swapping `HTTPSessionRepository` for a `BackendSessionRepository` is a one-line change inside `DependencyContainer`. Nothing in Presentation or Domain changes — that is the practical payoff of the layered architecture.

## 🈸 Requirements

- Xcode 16 or newer (the project uses synchronized folder groups).
- iOS 17 or newer (uses `@Observable`).
- Swift 6.2 toolchain (the project enables `-default-isolation=MainActor`).
- The Veriff SDK is added via Swift Package Manager (`https://github.com/Veriff/veriff-ios-spm`).

## 👟 Running

1. Open `veriffDemo.xcodeproj`.
2. Configure `Secrets.plist` as described in **Configuration** above.
3. Select an iOS Simulator destination (Previews and the SDK do not run on physical devices via Previews).
4. Build and run.

Each tap of "Start verification" creates a fresh session via `POST /v1/sessions` and launches the Veriff SDK with the resulting URL.
