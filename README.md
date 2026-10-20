# ST Authenticator

A small, offline, Android-only Flutter app that generates **time-based one-time codes (TOTP, RFC 6238)** for the apps *you* publish.

Use it to hand out short-lived unlock codes: a user asks you for access, you read them the current 6-digit code, and they type it into your app. Your app checks the code **offline** and unlocks. No server, no accounts, no network.

> This is not a consumer 2FA app. It is a single-operator tool: you are the only person who opens the authenticator.

---

## Contents

- [How it works](#how-it-works)
- [Features](#features)
- [Quick start](#quick-start)
- [Using the app](#using-the-app)
- [Add the verifier to your own app](#add-the-verifier-to-your-own-app)
- [Security](#security)
- [Project structure](#project-structure)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [More documentation](#more-documentation)

---

## How it works

```
 ┌───────────────────┐      secret (same Base32 string)      ┌──────────────────┐
 │  ST Authenticator │ ◄──────────────────────────────────► │  Your published  │
 │  (this repo)      │                                       │  app (verifier)  │
 └─────────┬─────────┘                                       └────────┬─────────┘
           │ shows 6-digit code                                       │ computes the same
           ▼                                                          ▼ code from the secret
   you read it to the user ───────► user types it ───────► code matches → unlock
```

Both sides compute the code independently from a shared **secret** and the current **time**. Nothing is sent over a network.

The two sides must agree on exactly three things:

| Shared item | Default |
|---|---|
| Secret (Base32 string) | you generate one per app |
| Digits | 6 (6–8 allowed) |
| Period | 30 seconds (15–60 allowed) |

Fixed for everyone: HMAC-SHA1, Unix time in UTC.

**Apps are data, not code.** Each app you support is just a name plus a secret that you add inside the running authenticator. You never rebuild this project to support a new app.

---

## Features

- Live codes for any number of apps, with a countdown ring.
- Tap a card to copy the code. Drag to reorder. Full-screen view for reading a code aloud.
- Add a secret by typing it, pasting it, pasting an `otpauth://` link, or scanning a QR code.
- Per-app digits (6–8) and period (15–60 s).
- Secrets are stored in the Android Keystore (`flutter_secure_storage`), never in plain preferences.
- No `INTERNET` permission, no analytics, no cloud backup, screenshots and screen recording blocked.
- Warns you when the phone's clock is not on automatic time (a wrong clock means wrong codes).
- Light and dark theme.

---

## Quick start

### Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) with Dart SDK `^3.13.0`
- Android SDK and a device or emulator (Android 7.0 / API 24 or newer)

### Run it

```bash
git clone <your-fork-or-this-repo-url>
cd st_authenticator

flutter pub get      # downloads packages and generates local build files
flutter test         # optional: run the test suite
flutter run          # run on a connected device / emulator
```

Build an installable APK:

```bash
flutter build apk --release
```

> **No secrets or key files are needed to build.** The repo ships with an empty app list. You add your own secrets inside the running app, and they stay on your device.
> The release build is signed with the debug key by default and uses the placeholder id `com.example.st_authenticator`. Change both before distributing it ([see below](#before-you-distribute-your-own-build)).

---

## Using the app

### 1. Create a secret for your app

A secret is a random Base32 string (letters `A–Z` and digits `2–7`). Use **at least 16 characters; 32 is recommended**, and use a **different secret for every app**.

```bash
python3 -c "import secrets,base64;print(base64.b32encode(secrets.token_bytes(20)).decode())"
```

or

```bash
head -c 20 /dev/urandom | base32
```

### 2. Add the app to the authenticator

1. Open the authenticator and tap **Add app**.
2. Enter a **name** (must be unique) and paste the **secret**.
   Or use the paste button for an `otpauth://` link, or the scan icon for a QR code.
3. Optionally pick an accent colour, and set digits/period under **Advanced** (leave them at 6 / 30 unless your app uses other values).
4. Save. A test code is shown so you can confirm it works.

### 3. Give a user a code

Open the app's card, read out the 6-digit code (or use the full-screen view), and the user enters it in your published app within the time window.

### Adding apps with a link or QR code

```
otpauth://totp/<Name>?secret=<BASE32>&digits=6&period=30
```

Only `totp` links with SHA-1 are accepted. Generate a QR image with `qrencode -o app.png '<link>'`.
**Treat the link and the QR image like the secret itself** because they contain it.

---

## Add the verifier to your own app

Your published app must verify the code. The rules it must follow:

1. Hold the same secret, digits and period.
2. Accept the code for the current time step **and ±1 step** (small clock differences).
3. Compare in **constant time**.
4. Accept each step **only once**: store the last accepted step and reject anything less than or equal to it.
5. Persist the unlock and the last accepted step.
6. Limit wrong attempts (about 5, then an increasing delay).

**Flutter/Dart app?** Copy [lib/core/totp.dart](lib/core/totp.dart) unchanged into your app. It is pure Dart and only needs the `crypto` package, so it is guaranteed to produce the same codes.

```yaml
dependencies:
  crypto: ^3.0.7
  flutter_secure_storage: ^11.2.0   # to persist the last accepted step
```

**Another language (Kotlin, Swift, JS, ...)?** Reimplement RFC 6238 exactly as described in the guide.

Ready-to-paste `TotpVerifier` code, the algorithm for other languages, common mistakes, attempt limiting and a test checklist are in
**[docs/VERIFIER_INTEGRATION.md](docs/VERIFIER_INTEGRATION.md)**.

Quick sanity check for any implementation (RFC 6238 test vector, secret `GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ`, 8 digits):

| Unix time | Code |
|---|---|
| 59 | `94287082` |
| 1111111109 | `07081804` |
| 1234567890 | `89005924` |

---

## Security

Read this before you rely on it.

- **Never commit a real secret** (not in code, tests, docs, screenshots or QR images). Real secrets belong only in the running authenticator and in your app's build.
- **An offline verifier must contain the secret.** Anyone who extracts it from your APK can generate valid codes for every user. This design deters casual sharing; it is *not* strong protection against a determined attacker. Obfuscate your build (`flutter build apk --obfuscate --split-debug-info=<dir>`), keep the secret out of obvious places, and use a different secret per app so one leak does not expose the others.
- **If a secret leaks, rotate it:** generate a new one, replace it in the authenticator (Edit → replace secret), and ship an app update.
- **There is no backup.** Secrets never leave the device, so if you uninstall the app or lose the phone, you lose them. Keep your own record somewhere safe.
- The `.gitignore` already excludes keystores, `.env` files, `key.properties`, Firebase configs and generated files that contain local paths. Keep it that way.

### Before you distribute your own build

- Change the application id from `com.example.st_authenticator` (`android/app/build.gradle.kts`).
- Create your own signing key and configure release signing. Do not commit the keystore.
- After adding any dependency, check that the **release** merged manifest still has no `INTERNET` permission (only `CAMERA` should remain).

---

## Project structure

```
lib/
  main.dart                 startup
  app.dart                  theme and app shell
  core/
    totp.dart               TOTP / HOTP / Base32 (pure Dart, no Flutter)
    otpauth.dart            otpauth:// link parser (pure Dart)
  models/auth_app.dart      the AuthApp record (name, secret, digits, period, colour)
  data/app_repository.dart  secure storage of the app list
  state/app_controller.dart app list state (ChangeNotifier)
  ui/                       screens and widgets
android/                    FLAG_SECURE, permissions, backup disabled
test/                       unit and widget tests
docs/                       detailed guides
```

Layers go `core` ← `models` ← `data` ← `state` ← `ui`. Nothing in `core/` imports Flutter, so it can be tested without a device.

---

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

Tests cover the RFC 6238 vectors, time-zone independence, Base32 handling, `otpauth://` parsing, storage behaviour (including corrupt data) and the add-app flow. Please keep the RFC vector tests green and keep `core/` free of Flutter imports.

**Non-goals** (please don't add): biometric lock, backup/export/cloud sync, any network access or analytics, support for algorithms other than SHA-1.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Codes never match your app | Your verifier used the Base32 **text** as the key (it must be the *decoded bytes*), a different secret, different digits/period, or not UTC epoch time. |
| Codes match only sometimes | The phone clock has drifted. Turn on automatic date & time. |
| "Invalid character" in the secret | `0`, `1`, `8` or `9` typed instead of letters (often `0` for the letter `O`). |
| "At least 16 characters" | The secret is too short after spaces and hyphens are removed. |
| A used code is accepted again | Your verifier is not persisting the last accepted step. |
| `flutter run` fails on a fresh clone | Run `flutter pub get` first, and make sure an Android SDK and device or emulator are available (`flutter doctor`). |

---

## More documentation

- **[docs/AUTHENTICATOR.md](docs/AUTHENTICATOR.md)**: full developer handbook (algorithm, data model, architecture, Android configuration, extending).
- **[docs/VERIFIER_INTEGRATION.md](docs/VERIFIER_INTEGRATION.md)**: how to build the verifier inside your own app.
