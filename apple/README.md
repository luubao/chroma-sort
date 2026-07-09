# Chroma Sort — Apple app

A thin, fully offline native shell around the game. `index.html` at the repo
root stays the single source of truth: a pre-build script copies it into the app
bundle, so there is nothing to keep in sync and no build step for the game
itself.

```
apple/
  project.yml                     XcodeGen definition (the .xcodeproj is generated, not committed)
  Scripts/MakeIcon.swift          draws every app-icon size with CoreGraphics
  ChromaSort/
    Sources/                      ~200 lines of Swift
    Resources/
      Info.plist
      ChromaSort.entitlements     App Sandbox, for the Mac App Store
      PrivacyInfo.xcprivacy       declares: no tracking, no data collected
      Assets.xcassets/            AppIcon, AccentColor, LaunchBackground
      www/index.html              generated at build time — gitignored
```

One target ships both platforms via `supportedDestinations: [iOS, macCatalyst]`,
so iOS and macOS share a bundle ID and a single App Store Connect record.

## Build

```bash
brew install xcodegen        # once
cd apple && xcodegen generate

# Simulator
xcodebuild -project ChromaSort.xcodeproj -scheme ChromaSort \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Mac
xcodebuild -project ChromaSort.xcodeproj -scheme ChromaSort \
  -destination 'platform=macOS,variant=Mac Catalyst' build
```

Re-run `xcodegen generate` after editing `project.yml`. Re-run
`swift Scripts/MakeIcon.swift` after editing the icon.

## What the native shell adds

These exist because a bare WebView wrapper is the single most common App Store
rejection (Guideline 4.2, Minimum Functionality). Each one is also a genuine
improvement over the web build:

- **Real haptics.** `navigator.vibrate` is a permanent no-op in WKWebView, so
  the game's haptics never fired on Apple platforms. `buzz()` now posts its
  vibration pattern over a `WKScriptMessageHandler` and `Haptics.swift` replays
  it on the Taptic Engine as timed transient events.
- **Fully offline.** The game loads from `file://` inside the bundle. The app
  requests no network entitlement and cannot reach the internet.
- **Native chrome that tracks the game's theme.** The page reports its
  light/dark state; the status bar style and the color behind the safe-area
  insets follow it.
- **Correct safe areas**, no rubber-band scrolling, no pinch-zoom, no long-press
  "Copy" callout, no white flash before first paint.

## Before you can submit

**You are not able to ship yet.** Your Keychain has only *Apple Development*
certificates:

| Certificate | Team ID |
|---|---|
| `Apple Development: luubao.nguyen@icloud.com` | `AY9WBDDV56` |
| `Apple Development: LuuBao Nguyen` | `66J39JTLFK` |

App Store submission additionally requires an **Apple Distribution**
certificate, which only exists on a **paid Apple Developer Program membership**
($99/year). Steps, in order:

1. Enroll at <https://developer.apple.com/programs/> and pick which of the two
   teams above is the publishing team.
2. Set the team once, so it stays out of the committed project file:
   ```bash
   export CHROMASORT_TEAM_ID=AY9WBDDV56   # or 66J39JTLFK
   ```
   `project.yml` reads it as `$(CHROMASORT_TEAM_ID)`. For CI, pass
   `DEVELOPMENT_TEAM=…` to `xcodebuild` instead.
3. Register the bundle ID `com.luubao.chromasort` under
   Certificates, Identifiers & Profiles. It is currently a guess based on your
   git identity — change it in `project.yml` if you own a different domain.
4. Create the app record in App Store Connect. Add the **macOS** platform to the
   same record so one listing covers both.

## Archive and upload

```bash
export CHROMASORT_TEAM_ID=AY9WBDDV56
cd apple && xcodegen generate

# iOS
xcodebuild -project ChromaSort.xcodeproj -scheme ChromaSort \
  -destination 'generic/platform=iOS' \
  -archivePath build/ChromaSort-iOS.xcarchive archive
xcodebuild -exportArchive -archivePath build/ChromaSort-iOS.xcarchive \
  -exportPath build/ios -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

# Mac Catalyst
xcodebuild -project ChromaSort.xcodeproj -scheme ChromaSort \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  -archivePath build/ChromaSort-Mac.xcarchive archive
```

You need an `ExportOptions.plist` with `method: app-store-connect` and your team
ID. Xcode's Organizer window ("Distribute App") writes one for you the first
time and is the easier path for a first submission.

## App Store Connect metadata still to write

- Screenshots: 6.9" iPhone (1320×2868) and 13" iPad are the required sizes;
  macOS wants 1280×800 or larger. `xcrun simctl io <udid> screenshot` produces
  them at the right pixel sizes.
- Description, keywords, support URL, marketing URL.
- Age rating (4+ — no objectionable content, no ads, no user-generated content).
- Privacy: answer "No" to data collection. `PrivacyInfo.xcprivacy` already
  declares this, but the questionnaire is separate and must agree.
- Export compliance is pre-answered by `ITSAppUsesNonExemptEncryption=false`.

## Guideline 4.2 — the remaining risk

The mitigations above make a real case, but a reviewer may still see a puzzle
that runs identically in Mobile Safari. If you want more insulation before
submitting, the highest-value additions are, in order:

1. **Game Center** leaderboards and achievements — replaces the local-only
   leaderboard with something the web build structurally cannot do.
2. **Widgets / Live Activity** for the daily puzzle streak.
3. **iCloud (CloudKit or KVS) sync** of progress across devices.

Each is a native capability with no web equivalent, which is precisely the
argument 4.2 asks you to make.
