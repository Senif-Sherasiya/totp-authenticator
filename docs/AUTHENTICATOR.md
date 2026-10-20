# Multi-App Authenticator — Developer Handbook

Audience: a developer joining the project. Read this once and you should be able to run, change, test and extend the app, and to implement the matching verifier in another app.

---

## 1. What this app is

A private, Android-only Flutter app that generates **time-based one-time codes (TOTP)** for several of the owner's own apps.

How it is used:

1. A user wants free access to one of the owner's published apps.
2. The owner opens this authenticator and picks that app from the list.
3. The owner reads the current 6-digit code and gives it to the user.
4. The user types it into the published app within ~30 seconds.
5. The published app verifies the code **offline** (no server) and unlocks access.

This is not a consumer 2FA app. There is one operator (the owner) and no end-user accounts.

### Explicit non-goals (do not add)
- No biometric / PIN lock.
- No backup, export or cloud sync.
- No backend, analytics or network access of any kind.
- No `INTERNET` permission.
- iOS, web and desktop are not supported targets.

---

## 2. Core concept: apps are data, not code

Each published app the owner supports is one **`AuthApp`** record: a name plus a secret. Adding a new app = adding a record at runtime. No rebuild is needed and no source change is required.

```
AuthApp {
  String   id             // UUID v4
  String   name           // unique, case-insensitive, trimmed
  String   secretBase32   // stored normalised (uppercase, no spaces/hyphens/padding)
  int      digits         // default 6, allowed 6–8
  int      periodSeconds  // default 30, allowed 15–60
  int      colorValue     // accent colour (ARGB int)
  DateTime createdAt      // UTC
}
```

Algorithm is fixed to HMAC-SHA1 for every app.

---

## 3. The TOTP algorithm (must match every verifier)

Standard RFC 6238 on RFC 4226 HOTP. Implemented by hand in `lib/core/otp/totp.dart` using only the `crypto` package (no TOTP library).

| Parameter | Value |
|---|---|
| Hash | HMAC-SHA1 |
| Digits | 6 (default; per-app 6–8) |
| Period | 30 s (default; per-app 15–60) |
| Epoch | Unix time, UTC |

Steps:

1. `counter = floor(unixSeconds / period)`.
2. Encode `counter` as 8 bytes, big-endian.
3. `hash = HMAC-SHA1(secretBytes, counterBytes)` → 20 bytes.
4. `offset = hash[19] & 0x0f`.
5. `binary = ((hash[offset] & 0x7f) << 24) | ((hash[offset+1] & 0xff) << 16) | ((hash[offset+2] & 0xff) << 8) | (hash[offset+3] & 0xff)`.
6. `code = (binary % 10^digits)`, left-padded with zeros to `digits` length.

### Critical rules
- **Time is the epoch, never wall-clock fields.** `DateTime.now().millisecondsSinceEpoch` is used, so the device time zone cannot change the result.
- **The key is the Base32-decoded bytes**, NOT the Base32 text. Using the text as the key is the single most common integration bug.
- **Secret format:** RFC 4648 Base32, alphabet `A–Z` and `2–7`. Case-insensitive; spaces, hyphens and `=` padding are ignored. `0`, `1`, `8`, `9` never occur.

### Verifier contract (what each published app must do)
- Accept the code for the current step **and ±1 step** (clock-skew tolerance).
- Accept each step's code **only once** (store the last accepted counter; reject a counter that is ≤ it).
- Therefore the authenticator shows **only the current step's code**.

Pseudocode for the verifier:

```
verify(input):
  now = unixSeconds()
  c = floor(now / period)
  for step in [c-1, c, c+1]:
    if step > lastAcceptedStep and hotp(secretBytes, step, digits) == input:
        lastAcceptedStep = step      // persist this
        return true
  return false
```

Use a constant-time comparison. Persist `lastAcceptedStep` so replay protection survives restarts.

### Test vectors
RFC 6238 Appendix B, SHA-1, ASCII secret `12345678901234567890`, 8 digits:

| Unix time | Code |
|---|---|
| 59 | 94287082 |
| 1111111109 | 07081804 |
| 1111111111 | 14050471 |
| 1234567890 | 89005924 |
| 2000000000 | 69279037 |
| 20000000000 | 65353130 |

The 6-digit code is the last 6 digits of these. A new verifier implementation should reproduce all six.

---

## 4. Secrets: rules for creating one

- Characters: `A–Z`, `2–7` only. Minimum 16 characters (app-enforced); **32 recommended** (20 random bytes).
- Must be **random** (cryptographically secure). Do not invent words or patterns.
- Use a **different secret per app**.
- The same string must be configured in the authenticator and in the verifier.

Generate one:

```
python3 -c "import secrets,base64;print(base64.b32encode(secrets.token_bytes(20)).decode())"
```
or
```
head -c 20 /dev/urandom | base32
```

Never commit a real secret to source control. The repo ships with an empty list.

---

## 5. otpauth:// links and QR codes

A secret can be added by scan or paste using the standard key-URI format:

```
otpauth://totp/<Name>?secret=<BASE32>&digits=6&period=30
```

Parsing rules (`lib/core/otpauth.dart`):
- Scheme must be `otpauth`, type must be `totp` (`hotp` is rejected).
- `secret` is required.
- `digits` 6–8 and `period` 15–60, otherwise rejected. Defaults 6 / 30.
- `algorithm` must be absent or `SHA1`.
- Name = `issuer` parameter if present, else the label; for a label `Issuer:account`, the part before `:`.
- Labels are URL-decoded (`My%20App` → `My App`); encode spaces when building links.

To make a QR image: `qrencode -o app.png '<link>'`. Treat links and QR images like the secret itself — they contain it.

---

## 6. Architecture

```
lib/
  main.dart                   startup: builds controller + clock, runs app
  app.dart                    MaterialApp, Material 3 light/dark theme, AppScope
  core/
    totp.dart                 PURE DART. TOTP, HOTP, Base32. No Flutter imports.
    otpauth.dart              PURE DART. otpauth:// parser.
  models/
    auth_app.dart             AuthApp model, JSON, codeAt()/secondsLeftAt()
  data/
    app_repository.dart       AppRepository interface, KeyValueStore,
                              SecureKeyValueStore, StoredAppRepository
  state/
    app_controller.dart       ChangeNotifier: load/add/update/delete/reorder
  ui/
    app_scope.dart            InheritedWidget exposing controller + clock
    second_clock.dart         shared clock ticking on real second boundaries
    home_screen.dart          list, empty state, FAB
    code_card.dart            one card + copy-to-clipboard
    full_screen_code.dart     large code view
    app_form_screen.dart      add + edit form
    scan_screen.dart          QR scanner (mobile_scanner)
    time_banner.dart          UTC time + "enable automatic time" warning
    countdown_ring.dart       ring widget
    palette.dart              accent colours, amber/red urgency colours
    dialogs.dart              delete / replace-secret confirmations
android/app/src/main/
  kotlin/.../MainActivity.kt  FLAG_SECURE
  AndroidManifest.xml         permissions, backup disabled
  res/xml/data_extraction_rules.xml
test/                         unit + widget tests
```

Layering: `core` (pure) ← `models` ← `data` ← `state` ← `ui`. Nothing in `core` may import Flutter, so it stays unit-testable with no platform.

### State management
Plain `ChangeNotifier`. `AppController` holds the list; `SecondClock` is a second `ChangeNotifier`. Widgets use `ListenableBuilder`. `AppScope` hands both down. No Riverpod/Provider/Bloc, deliberately.

### The clock
`SecondClock` fires on every real **second boundary**. After each tick it recomputes the delay from the current epoch time instead of using a fixed 1 s periodic timer, so it does not drift. All cards listen to the same clock, so they refresh together and step changes show on time. On app resume it re-syncs immediately.

### Storage
- `AppRepository` is an interface so it can be faked in tests.
- `StoredAppRepository` keeps the **entire list (including secrets) as one JSON string** under key `auth_apps_v1`, written through `KeyValueStore`.
- Production `KeyValueStore` = `flutter_secure_storage` (Android Keystore-backed). Secrets are never in plain SharedPreferences.
- Tests use an in-memory `FakeStore` (`test/fakes.dart`).
- Corrupt/unreadable stored data throws `StorageException`; the UI shows an error with Retry. The repository **never overwrites unreadable data** with an empty list.
- Name uniqueness is trimmed and case-insensitive (`DuplicateNameException`).
- Reorder: `onReorderItem` supplies the **final** index; `moveItem()` does a plain remove + insert. The controller updates the list first (so the drop does not snap back), then persists, and reloads from storage if saving fails.

---

## 7. Features and behaviour

**Home**
- One card per app: initial avatar in accent colour, name, live code grouped as `123 456` (8 digits: `1234 5678`), countdown ring.
- Tap: copies the code without the space and shows a snackbar.
- Long-press and drag: reorder.
- ⋮ menu: Show full-screen, Edit, Delete.
- Empty state: "Add your first app".
- Time banner on top: current UTC time and a warning to enable automatic date & time.

**Full-screen**
- Very large code, large ring, Copy button.
- Last 5 seconds: code turns amber; last 3 seconds: red. The **next** code is shown in small text during the last 5 seconds.

**Add / Edit**
- Name (required, unique) and Secret (Base32). Secret is hidden by default with a show/hide toggle.
- Validation: at least 16 characters after normalisation; invalid characters are reported by name and Unicode value.
- Paste button: understands both a raw secret and a full `otpauth://` link.
- Scan icon (add mode): opens the QR scanner.
- Accent colour picker. Advanced section: digits 6–8, period 15–60.
- Add: after saving, shows a test code so the owner can confirm it works.
- Edit: if secret, digits or period changed, a confirm dialog warns that old codes will stop working.

**Delete**
- Confirm dialog warning the secret is lost unless saved elsewhere.

---

## 8. Android configuration (do not undo)

- **FLAG_SECURE** is set in `MainActivity.onCreate` before `super.onCreate`. It blocks screenshots, screen recording and the recents thumbnail on every screen. No plugin is used.
- **No INTERNET permission.** A transitive dependency (ML Kit via `mobile_scanner`) adds `INTERNET` and `ACCESS_NETWORK_STATE` to the merged manifest. They are removed with `tools:node="remove"` in `AndroidManifest.xml`. After adding any dependency, check the **release** merged manifest:
  `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`
  It should contain only `CAMERA`. (The debug manifest keeps `INTERNET` for hot reload; that is normal.)
- **CAMERA** is requested only for QR scanning; `uses-feature camera` is `required="false"`.
- **Backups disabled:** `allowBackup="false"`, `fullBackupContent="false"` and a `data_extraction_rules.xml` excluding everything. Secrets must not leave the device, and restored Keystore-encrypted data would be unreadable anyway.
- `minSdk` is raised to 24 (required by `flutter_secure_storage`).
- The app id is still `com.example.st_authenticator` and release builds are signed with the debug key. **Change both before any real distribution.**

---

## 9. Dependencies

| Package | Why |
|---|---|
| `crypto` | HMAC-SHA1 |
| `flutter_secure_storage` | Keystore-backed storage of the JSON list |
| `uuid` | App ids |
| `mobile_scanner` | QR scanning |

---

## 10. Running and testing

```
flutter pub get
flutter analyze
flutter test
flutter run                      # device or emulator
flutter build apk --release
```

Tests (`test/`):
- `totp_test.dart` — RFC 6238 vectors, same instant in UTC / +05:30 / −07:00, stable within a step and changing at the boundary, non-default digits/period, Base32 decoding and errors.
- `otpauth_test.dart` — URI parsing and rejection cases.
- `repository_test.dart` — add / update / delete / reorder / duplicate rejection / corrupt-data safety, using the fake store.
- `widget_test.dart` — empty state, validation message, add flow, test-code dialog.

The clock is not started in widget tests (no timers). Keep it that way: construct `SecondClock()` without calling `start()`.

---

## 11. End-to-end verification with a real app

1. In the authenticator: Add app → enter the name and the same secret the verifier holds → note the test code.
2. Enter the code in the published app within the step. Expected: accepted.
3. Enter the same code again. Expected: **rejected** (one-time use).
4. Wait for the next step and enter the new code. Expected: accepted.
5. Clock check: turn off automatic time and move the phone forward by about 2 minutes. Expected: codes rejected, and the banner shows the shifted UTC time.

---

## 12. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Codes never match the verifier | Verifier uses the Base32 **text** as the key instead of decoded bytes; different secret; different digits/period; verifier not using UTC epoch time. |
| Codes match sometimes | Device clock drift; automatic date & time is off. |
| "Invalid character" on the secret | `0`, `1`, `8`, `9` typed instead of letters (commonly `0` for the letter `O`). The message names the character. |
| "At least 16 characters" | Secret too short after stripping spaces/hyphens. |
| Reused code accepted | Verifier is not persisting the last accepted step. |
| Edit/Delete lost a secret | Expected: no backup exists. Secrets must be kept elsewhere by the owner. |
| `INTERNET` shows in the release manifest | A new dependency re-added it; add a `tools:node="remove"` entry. |

---

## 13. Extending

- **New published app:** nothing to code. Add it in the UI.
- **Different digits/period for one app:** use the Advanced section; the verifier must use the same values.
- **New algorithm (SHA-256/512):** not supported by design. It would need changes in `Totp.hotp`, the model, the otpauth parser (currently rejects non-SHA1) and every verifier.
- **Different storage:** implement `AppRepository` (or `KeyValueStore`) and pass it in `main.dart`.
- Keep `core/` free of Flutter imports and keep the RFC vector tests green.
