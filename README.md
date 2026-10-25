# moop.

One photo a day. One mood. One short sentence.

moop reads the mood of a photo you take and answers with a single word and a single line. The reading happens entirely on your iPhone with Apple Intelligence. There is no feed and nothing is posted. An account is optional: moments stay on the iPhone by default, and you can choose to sync them through your own private iCloud.

## Who it's for

People who want to notice their days without turning them into a chore: someone who finds journaling too heavy, mood trackers too clinical, and social apps too loud. They take a photo anyway. moop gives that photo a gentle name and keeps a quiet record of it.

## Design choices that follow from that

- **One word, never a score.** A mood is a suggestion, not a verdict. Every result says "a guess, not a verdict", and "Why this word?" shows what the reader saw.
- **Low pressure by design.** A streak survives one missed day, a gap is "part of the story", and an empty month says it is empty instead of showing zeros. Missing days are never guessed.
- **Private by construction.** The model runs on device. The camera, the crop and the reading never touch a network, and the copy says so on the screens where it matters.
- **An account is a choice, not a gate.** "Continue without Account" is as prominent as "Continue with Apple". Without an account nothing is ever uploaded. Signing in with Apple and having iCloud are treated as two separate facts, so a sign-in never claims a moment is synced.
- **Local first, always.** Every moment is saved on the iPhone before anything else happens. Capture, reading and history all work offline, and sync only ever catches up afterwards.
- **Sync is not a backup.** Deleting a moment on one iPhone removes it on the others, so the app also saves a plain zip backup to Files, which restores without duplicates.
- **Honest status.** "Up to date" is only shown after a send that left nothing waiting and nothing failed. Otherwise it says what is really happening: waiting, offline, storage full, needs attention.
- **Every photo is square.** The viewfinder, the crop, the review, the result and every card are 1:1, so a week of photos reads as one grid. Library photos go through an adjustable square crop and keep their full resolution.
- **Honest loading.** The model reports no progress, so the Reading screen uses a shuttle bar rather than a fake percentage.
- **The reader is optional.** If a read fails, the photo can still be kept without a word.
- **Light and Night from one token.** Every colour resolves per mode, and text on the lime accent is always dark in both.

## App flow

```
Splash (Lottie) → Storage choice → First run → Tabs
                  ├─ Continue with Apple → iCloud check → Turn on iCloud Sync (or stay local)
                  └─ Continue without Account
                              │
   Today ─────────────────────┼─ Camera ─ Crop (library only) ─ Review ─ Reading ─ Result
     └─ Streak                │                                                  └─ Why this word?
   History (week · calendar · month)
     ├─ Day detail (every moment of that day, delete)
     └─ Compare (this month vs the month before)
   Settings (theme, reminder, storage and iCloud status, backup to Files, restore, delete everything)
```

- **Today** shows the latest moment and opens the camera.
- **Camera** is a square viewfinder with real lens stops (0.5x, 1x, 2x), flip, and a library button.
- **Result** keeps the photo, the mood and the sentence, and can try another line.
- **Storage choice** is the first screen for new people. Existing people skip it and stay in local mode with every moment where it was.
- **Settings** shows where moments live and the real sync state, and holds Save Backup to Files, Restore from Backup, stopping sync, and a delete that says exactly what it covers.
- **History** has three lenses. Week lists the days, Calendar marks each day with its mood, Month draws each week as a ribbon of moods.

## Tech stack

| Area | Choice |
| --- | --- |
| Language / UI | Swift, SwiftUI, `@Observable` (MVVM) |
| Target | iOS 27 |
| Mood reading | FoundationModels on Apple Intelligence, `@Generable` with guided decoding, so the model can only answer with a valid mood |
| Camera | AVFoundation (`AVCaptureSession`, virtual multi-lens device, preview layer) |
| Library | PhotosUI `PhotosPicker` |
| Motion | Lottie (`lottie-ios`) for the splash, SwiftUI animations elsewhere |
| Reminders | UserNotifications, one-shot calendar triggers re-armed on launch |
| Storage | JPEGs plus `index.json` in the app's Documents folder |
| Account | Sign in with Apple (AuthenticationServices), user id kept in the Keychain |
| Sync | CloudKit private database through `CKSyncEngine`, one record per moment with the photo as a `CKAsset` |
| Backup | Plain zip (manifest, index, photos) with a SHA-256 per photo, via `ZIPFoundation` |
| Fonts | DM Sans (bundled) and Instrument Serif (system serif stands in until the file is added) |
| Project | XcodeGen (`project.yml`) |

## Project structure

```
moop/
├── project.yml                    ← XcodeGen spec, Lottie package
├── Sources/
│   ├── App/
│   │   ├── MoopApp.swift          ← @main, DEBUG self-checks
│   │   └── RootView.swift         ← splash → first run → tabs, per-tab NavigationStack
│   ├── Models/
│   │   ├── Mood.swift             ← @Generable enum: calm, adventure, homey, playful, mystery
│   │   ├── Snap.swift             ← one saved moment (on-disk key stays "vibe")
│   │   ├── Routes.swift           ← typed Today / History routes
│   │   ├── Block.swift            ← why the model cannot run
│   │   ├── StorageMode.swift      ← local / apple, auth state, iCloud availability, sync state
│   │   ├── Theme.swift            ← system / light / dark
│   │   ├── Prefs.swift            ← UserDefaults keys
│   │   └── StreakReminder.swift
│   ├── Services/
│   │   ├── MoodEngine.swift       ← two-turn read: mood + reason, then a sentence
│   │   ├── CameraSession.swift    ← capture, zoom stops, square crop on capture
│   │   ├── SnapStore.swift        ← persistence, day / week / month queries, streak, merge, sync hooks
│   │   ├── BackupService.swift    ← zip backup and validated restore, with a launch self-check
│   │   ├── CloudSync.swift        ← CKSyncEngine private iCloud sync
│   │   ├── Keychain.swift         ← Apple user id
│   │   └── ReminderScheduler.swift
│   ├── ViewModels/                ← all logic lives here, views stay dumb
│   │   ├── AppViewModel.swift     ← tab, navigation paths, camera cover
│   │   ├── AccountViewModel.swift ← storage mode, Sign in with Apple, sync, backup, restore, delete
│   │   ├── CameraViewModel.swift  ← capture, library, crop hand-off
│   │   ├── MoodReader.swift       ← read state, retry, another line
│   │   ├── TodayViewModel.swift
│   │   ├── ResultViewModel.swift
│   │   ├── HistoryViewModel.swift ← week rows, calendar grid, month ribbons, compare
│   │   ├── DayViewModel.swift
│   │   ├── StreakViewModel.swift
│   │   ├── SettingsViewModel.swift
│   │   └── OnboardingViewModel.swift
│   ├── Views/
│   │   ├── StorageChoiceView.swift← first screen: Apple or no account
│   │   ├── TodayView.swift
│   │   ├── CameraFlow.swift       ← CameraView, ReviewView, ReadingView in one cover
│   │   ├── CropView.swift         ← adjustable square crop
│   │   ├── ResultView.swift       ← + WhySheet
│   │   ├── HistoryView.swift
│   │   ├── DayView.swift
│   │   ├── StreakView.swift
│   │   ├── CompareView.swift
│   │   ├── SettingsView.swift
│   │   ├── FirstRunView.swift
│   │   ├── SplashView.swift       ← Lottie, font-name bridge for DM Sans
│   │   └── Components/
│   │       ├── MoopChrome.swift   ← MoopHeader, MoopAction, MoopBadge, PhotoCard, MoopBack, MoopTrash, MoopRow
│   │       ├── MoopTabBar.swift
│   │       ├── ShutterButton.swift← + ZoomPicker
│   │       └── CameraPreview.swift
│   ├── Design/                    ← design system
│   │   ├── MoopColors.swift       ← Light / Night tokens + one colour per mood
│   │   ├── MoopType.swift         ← poster / line / title / statement / reading / detail / micro
│   │   └── MoopSpace.swift        ← Space and Edge scales
│   └── Extensions/
│       ├── UIImage+Photo.swift    ← upright(), cropped(to:), squareCropped()
│       ├── OpenSettings.swift
│       └── Date+Identifiable.swift
└── Support/
    ├── Info.plist
    ├── moop.entitlements          ← Sign in with Apple, iCloud / CloudKit, push
    ├── Fonts/                     ← DM Sans Regular / Medium / SemiBold / Bold
    ├── Motion/                    ← splash-light.json, splash-dark.json
    └── Assets.xcassets            ← app icon, accent colour
```

## Design system

**Colour.** Each token is one name with a Light and a Night value, resolved by the system.

| Token | Role |
| --- | --- |
| `canvas`, `veil`, `highlight`, `scene` | backgrounds and quiet fills |
| `ink`, `onDark` | text on the canvas |
| `onAccent` | dark text that stays dark on lime in both modes |
| `onViolet` | flips with violet (light by day, dark by night) |
| `violet`, `blue` | links, active states |
| `citrus` | the one loud action per screen |
| `alert` | destructive only (the trash icon, delete alerts) |
| `emotion(_:)` | calm blue, adventure green, homey coral, playful yellow, mystery grey |

**Typography.** Instrument Serif for the big display lines, DM Sans for everything else.

| Style | Face | Size |
| --- | --- | --- |
| `poster` | serif | 52 |
| `line` | serif | 38 |
| `title` | DM Sans Bold | 26 |
| `moodWord` | DM Sans Bold | 21 |
| `statement` | DM Sans Medium | 18 |
| `reading` | DM Sans Regular | 16 |
| `detail` | DM Sans Medium | 13 |
| `micro` | DM Sans SemiBold | 11 |

**Spacing and shape.** `Space` runs dot 4, tick 8, cut 12, beat 18, gutter 26, section 38, scene 52. `Edge` runs slight 6, soft 12, organic 18, block 24.

**Motion.** A Lottie splash where the `p` turns into a `d` (light and dark versions), a shuttle progress bar on the Reading screen, a pressed state on the shutter, and short ease-out transitions for the splash hand-off and month changes.

**Components.** `PhotoCard` (always 1:1), `MoopAction` (the lime button), `MoopBadge`, `MoopHeader`, `MoopBack` (one back link for every pushed screen), `MoopTrash` (red `trash` symbol, 44pt target, accessibility label).

## Running it

Apple Intelligence must be on, on a device or simulator that supports it. The camera needs a real iPhone; the simulator can use the library.

Sign in with Apple and iCloud sync need a signed build. The first build to a device from Xcode registers the Sign in with Apple and iCloud capabilities, and the iCloud container `iCloud.com.rizkyinsania.moop`, on your developer team.

```bash
xcodegen generate
open moop.xcodeproj
```

## Status

Verified in the iOS Simulator (Light and Night): storage choice, local mode, backup to Files, restore, and the self-check for backup round trips, repeated restores and damaged files.

Not verified yet: a completed Sign in with Apple, and iCloud sync between two iPhones. Both need real devices and an iCloud account. The square viewfinder and the physical camera have not been tested on a real iPhone either.
