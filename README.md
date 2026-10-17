<p align="center">
  <img src="assets/icon/icon.png" alt="Findly logo" width="112" />
</p>

<h1 align="center">Findly</h1>

<p align="center"><em>Lost something? Find your way back.</em></p>

<p align="center">
  A cloud-connected lost-and-found app for campuses and shared spaces, built with
  Flutter and Supabase.
</p>

---

## The problem

Lost-and-found information is scattered across WhatsApp groups, social media
posts and word of mouth. People who find something struggle to reach the owner,
and owners rarely see the right post in time.

Findly gives a community, such as a university, one place to report lost and found
items, see likely matches between them, and track each report until it is resolved.

**Intended users:** university students and staff, and anyone who loses or finds
belongings in libraries, lecture halls, public transport and other shared spaces.

## Features

- **Lost and found reports.** Title, category, description, location, date and
  an optional photo, with validation on the device and in the database.
- **Explainable matching.** Each active lost report is compared with active found
  reports. Every suggestion shows a 0–100 score, a per-signal breakdown and the
  reasons it was suggested.
- **Search and filters.** Free-text search across title, description, category
  and location. It combines with Lost/Found, Active/Resolved and category filters.
- **Status workflow.** Owners can mark a report resolved or reopen it. Resolved
  reports leave the matching pool immediately.
- **Accounts.** Email sign-up with confirmation, sign in, password reset through
  a deep link, and sign out.
- **Owner-only actions.** Only a report's owner can edit, resolve or delete it.
  The database enforces this, not just the UI.
- **Polished UI.** Material 3, light and dark themes (System / Light / Dark in
  Settings), the Poppins typeface, an animated splash, shimmer loading skeletons,
  and loading, empty, error and retry states throughout.
- **Privacy by default.** No contact details are collected. Users' email
  addresses are never shown to others. Photos are private and served through
  short-lived signed URLs.

## Screenshots

_Screenshots will be added here._

## Tech stack

| Layer | Choice |
| --- | --- |
| App | Flutter (Dart 3), Material 3 |
| State management | `provider` (`ChangeNotifier` controllers) |
| Backend | Supabase: PostgreSQL, Auth, Storage |
| Authorization | Row Level Security, column privileges and Storage policies |
| Session storage | `flutter_secure_storage` (Android Keystore–backed) |
| Images | `image_picker`, uploaded to a private Storage bucket |

## Architecture

```
lib/
├── main.dart                  # bootstrap: config check, splash, Supabase init
├── app.dart                   # MaterialApp, theming, auth-based routing
├── core/                      # config, errors, theme tokens, utilities
├── models/                    # typed domain models (reports, filters, matches)
├── services/
│   └── matching_service.dart  # pure, deterministic matching engine
├── data/                      # repository interface + Supabase implementation
├── state/                     # ChangeNotifier controllers (auth, reports, settings)
├── screens/                   # auth, home, report form, details, matches, settings
└── widgets/                   # reusable UI components
supabase/
├── migrations/                # schema, constraints, RLS and Storage policies
└── seed/                      # optional demo data (development only)
```

- **Screens** render state and forward user intent. They contain no business
  logic.
- **Controllers** (`state/`) hold app state and update it only after the server
  confirms a change, so the UI never shows unsaved data.
- **`ReportRepository`** is the persistence boundary. The app uses the Supabase
  implementation; tests use an in-memory one.
- **Models and the matching engine** are plain Dart with no Flutter or network
  dependencies, so they are fully unit-testable.

## Matching algorithm

Matching compares **active lost** reports with **active found** reports only. A
report is never matched with itself, and resolved reports are excluded. Each
candidate pair is scored out of 100:

| Signal | Max points | Method |
| --- | ---: | --- |
| Category | 40 | Same category, or nothing |
| Description | 30 | Jaccard similarity of keywords from title and description |
| Location | 20 | Identical normalized text scores fully; otherwise Jaccard similarity of meaningful place words |
| Date | 10 | Linear decay from the same day to 0 at a 14-day gap |

Details:

- **Text normalization.** Text is lower-cased, punctuation is removed and common
  stop words are dropped. Simple plurals are folded, so *keys* matches *key*.
  Letters from any script are kept, including Sinhala and Tamil vowel signs.
- **Plausibility.** If the found date is more than one day before the lost date,
  the pair is discarded.
- **Threshold and ranking.** Pairs scoring below 25 are hidden. The rest are
  sorted by score, then by the closer date, and capped at 20 results. Scores of
  70 or more are labelled *Strong*, 45 or more *Possible*.
- **Configurable.** All weights and thresholds live in `MatchingConfig`.
- **Honest by design.** Location matching compares wording only and makes no
  claim that two places are physically close. The app states that a high score
  is a hint, not proof of ownership.

The weights are initial product assumptions, not values tuned on real data.

## Data model and security

One table, `public.reports`, plus one private Storage bucket, `report-photos`.
The full schema is in
[`supabase/migrations`](supabase/migrations/20261016000000_initial_schema.sql).

| Data | Who can access it |
| --- | --- |
| Reports (title, description, category, location, dates, status) | Read by any signed-in user; never by anonymous visitors |
| Creating, editing, resolving or deleting a report | Only its owner |
| `owner_id`, timestamps, demo flag, report type after creation | Set by the server; clients cannot write them |
| Photos | Uploaded only into the owner's own folder (JPEG, PNG or WebP, 5 MB max, no overwrites); visible to signed-in users only once attached to a report |
| Email addresses | Never exposed through the reports API |

The database also checks text lengths, rejects future dates and limits each user
to 20 new reports per 24 hours.

These rules are verified by
[`tool/security_check.sh`](tool/security_check.sh), which calls the Supabase APIs
directly as two separate users, bypassing the app. The latest results are in
[`docs/SECURITY_TESTS.md`](docs/SECURITY_TESTS.md).

## Getting started

### Prerequisites

- Flutter (stable channel) with Dart 3
- Android SDK, with a physical Android device or an emulator
- A free [Supabase](https://supabase.com) project

### 1. Set up Supabase

Follow [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md) to create the project,
run the migration and configure authentication redirects.

### 2. Configure the app

```bash
cp env/dev.example.json env/dev.json
```

Fill in your project URL and **publishable (anon) key**. `env/dev.json` is
git-ignored.

> **Never** put the `service_role` / secret key or the database password in the
> app or this repository. The publishable key is designed to be public;
> security comes from the database policies.

### 3. Run

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

In VS Code, the **Findly (dev)** launch configuration passes the same flag.

## Testing

```bash
flutter analyze
flutter test
```

The suite covers:

- **Unit tests:** text normalization, each matching component and the final
  score, eligibility rules, sorting, boundaries, validation, filters, status
  transitions and settings persistence.
- **Widget tests:** home screen rendering, search and filters, form validation
  and submission, resolving with confirmation, owner-only actions, matches,
  error and retry states, and theme switching.

Widget tests run against an in-memory repository, so they need no network
access or credentials.

To check the server-side rules against your own development project:

```bash
FINDLY_USER_A_EMAIL=a@example.test FINDLY_USER_B_EMAIL=b@example.test \
  tool/security_check.sh
```

The script reads the URL and publishable key from `env/dev.json` and prompts
for both passwords without echoing them.

## Building

```bash
# Installable APK for testing on a device
flutter build apk --release --dart-define-from-file=env/dev.json

# App Bundle for Google Play (requires a release signing key)
flutter build appbundle --release --dart-define-from-file=env/dev.json
```

An **APK** installs directly on a device. An **AAB** is the format Google Play
requires; Play generates optimized APKs from it. Release signing is not
configured yet: release builds currently use the debug key and cannot be
uploaded to Play. Keystores are git-ignored by design.

## Known limitations

- **No offline support.** Creating or editing reports needs a connection; there
  is no offline queue.
- **Location is free text.** There are no coordinates or geospatial distance.
- **No in-app contact flow yet.** Owners and finders cannot message each other
  through the app.
- **No moderation tools.** Abuse is limited only by the per-user rate limit and
  owner-only edits.
- **File types are enforced by declared MIME type.** Storage checks the type the
  client declares. The app verifies image bytes before uploading, but a modified
  client could store a mislabelled file in its own folder.
- **Default email sender.** Supabase's built-in mailer is rate-limited and meant
  for development; production needs a custom SMTP provider.

## Roadmap

- Privacy-safe in-app messaging between owner and finder
- Push notifications for new strong matches
- Map-based locations and distance-aware matching
- Moderation and reporting of inappropriate content
- iOS release

## Credits

- [Poppins](https://github.com/itfoundry/Poppins) typeface, SIL Open Font
  License 1.1 (see `assets/licenses/poppins_OFL.txt`)
- Third-party package licenses are listed in the app under
  **Settings → Open-source licenses**.
