# Dompetektif

> **Usut tuntas ke mana uangmu pergi.**

Dompetektif is a detective-themed personal finance app built with Flutter. It
turns expense tracking into a case file: wallets are crime scenes, receipts are
evidence, budgets are **Batas TKP**, and a shared household ledger becomes a
**Tim Investigasi**. The product language is Indonesian-first, with a complete
English translation.

<p align="center">
  <img src="assets/icon/app_icon_512.png" width="144" alt="Dompetektif app icon" />
</p>

The app runs as a real Android app and an installable web PWA. It is
offline-first: every screen reads from an on-device Hive store, while an outbox
syncs to Supabase when connectivity returns. Without Supabase credentials it
boots into a fully populated local demo mode, so the project can be evaluated
without provisioning a backend.

---

## What is inside

| Area | Implementation |
| --- | --- |
| Authentication | Email/password, Google OAuth, demo session, biometric app lock |
| Cloud data | Supabase Postgres, RLS, realtime postgres changes, private receipt storage |
| Wallets | Multiple cash/bank/e-wallet accounts, opening balances, shared membership |
| Ledger | Income, expense, transfer, notes, merchants, receipts, edit/delete, filters |
| Categories | Ten localized system categories, custom categories with keywords |
| Receipt OCR | Google ML Kit on Android, paste-text fallback on web, deterministic parser |
| Budgets | Per-category monthly limits, 80% warning, over-budget state, local notifications |
| Recurring | Daily/weekly/monthly/yearly rules, automatic materialization, next-run reminders |
| Analytics | Cash-flow chart, category donut, top merchants, month change, anomaly signals |
| AI report | `investigation-report` Edge Function proxying a free-tier model, heuristic fallback |
| Export | Branded PDF and CSV reports through the platform share/save sheet |
| Collaboration | Shared wallets, invite codes, membership roles, case-note chat, presence |
| Offline | Hive source of truth, write outbox, pull cursors, soft deletes, last-write-wins |
| Security | RLS, biometric lock, hidden amounts, local data wipe on sign-out, no Android backup |
| Design | Dark-first case-file UI, warm light theme, responsive layouts, custom app icon |
| Localization | Indonesian and English, custom inline delegate, localized money/date formats |
| Quality | Unit + widget tests, Dart format gate, `flutter analyze`, GitHub Actions |
| Delivery | Automated web bundle and release APK artifacts |

---

## Quick start (no backend)

Requirements: Flutter **3.47.8** or newer, Dart 3.13+, and the usual Android
toolchain for device builds.

```bash
flutter pub get
flutter run -d chrome
```

On the auth screen choose **Masuk sebagai detektif demo** / **Enter as demo
detective**. The seeder creates a believable investigation with wallets,
transactions, budgets, receipts, recurring rules, notes, and a report. Demo data
is stored in Hive (IndexedDB on web, app documents on Android) and survives
reloads.

Useful commands:

```bash
flutter test
flutter analyze
dart format lib test
flutter build web --release
flutter build apk --release
```

Android release builds enable Java core-library desugaring for local notifications and
apply R8 keep rules for optional ML Kit scripts that are not bundled, plus the ML Kit
component registrars that are discovered and instantiated reflectively at startup.
Kotlin incremental caching is disabled in `android/gradle.properties` so Windows
checkouts with the Pub cache on a different drive build reliably.

### Web build on GitHub Pages

The web build is published to GitHub Pages:
<https://mtegarpamungkas.github.io/dompetektif/>.

Publish an update with:

```powershell
pwsh tool/deploy_pages.ps1
```

The script builds `build/web_pages` with the project base path and force-pushes
it to the `gh-pages` branch, which GitHub Pages serves directly. When
`env.json` exists the build connects to Supabase (email and Google login);
without it the page falls back to local demo mode. The Pages URL must be listed
under **Authentication → URL Configuration → Redirect URLs** in Supabase.

---

## Connect Supabase

1. Create a Supabase project.
2. Apply the migrations:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push
   ```

3. Deploy the report function and set a free-tier AI key:

   ```bash
   supabase functions deploy investigation-report
   supabase secrets set AI_API_KEY=<key> AI_MODEL=google/gemini-2.0-flash-exp:free
   ```

4. Copy `env.example.json` to `env.json` and fill in the project URL and anon
   key. Then run:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

   For release builds:

   ```bash
   flutter build web --release --dart-define-from-file=env.json
   flutter build apk --release --dart-define-from-file=env.json
   ```

5. In Supabase **Authentication → URL Configuration**, set the web site URL and
   add `http://localhost:8080` plus `dev.dompetektif://login-callback` as
   redirect URLs. Enable the Google provider if Google sign-in is required.

The schema, RLS model, invite RPCs, realtime publication, storage policies, and
backend setup are documented in [`supabase/README.md`](supabase/README.md).

### Configuration

| Key | Used by | Purpose |
| --- | --- | --- |
| `SUPABASE_URL` | Flutter | Supabase project URL |
| `SUPABASE_ANON_KEY` | Flutter | Public anon key; RLS protects all data |
| `APP_SCHEME` | Flutter | OAuth deep-link scheme, default `dev.dompetektif` |
| `AI_API_KEY` / `OPENROUTER_API_KEY` | Edge Function | Free-tier AI provider key |
| `AI_MODEL` | Edge Function | OpenAI-compatible model id |
| `AI_BASE_URL` | Edge Function | Provider base URL, default OpenRouter |

When `SUPABASE_URL` or `SUPABASE_ANON_KEY` is empty, the app deliberately falls
back to local demo mode and labels it in the UI. The AI function has the same
philosophy: no key means a deterministic heuristic report, never a broken screen.

---

## Architecture

```
lib/
  app/            app root, router, shell, biometric lock, maintenance tasks
  core/           config, DI, localization, responsive rules, theme, widgets
  domain/         entities, pure analytics, repository contracts, use cases
  data/           Hive store, mappers, gateways, services, seed, sync, repository impls
  features/       auth, dashboard, ledger, evidence, reports, team, settings, budgets
```

The dependency direction is `presentation → domain ← data`:

- Pages and cubits never read Hive directly. They call domain use cases.
- Repositories write to Hive first, then enqueue an outbox operation.
- Pure calculations (balances, budgets, anomalies, receipt parsing, recurrence)
  live in `domain` and are unit tested.
- `get_it` composes repositories, cubits, device services, and the sync engine.
- `go_router` uses a five-branch shell: **Dashboard**, **Ledger**, **Evidence**,
  **Reports**, and **Team**, with full-screen settings/detail routes.

Money is stored as integer minor units everywhere (`Money.amountMinor`). IDR uses
zero decimals; other currencies default to two. This avoids floating-point drift
in balances and exports.

### Offline-first and realtime

1. A write updates Hive immediately with a local timestamp and `is_pending`.
2. The same payload is appended to an outbox.
3. `SyncEngine` pushes the outbox to Supabase, then pulls rows changed since each
   table's `updated_at` cursor.
4. Realtime postgres changes trigger a debounced pull for shared wallets.
5. Conflicts use last-write-wins. Soft-deleted rows stay in sync as tombstones.
6. Sign-out clears synced case data and cursors while keeping theme/locale
   preferences. This prevents one account's wallets and receipts from leaking
   into the next session on a shared device.

The `investigation-report` function receives the caller's JWT, so every query is
RLS-scoped. It aggregates in the function, asks the AI provider for structured
JSON, validates the response (including transaction ids and amounts), and returns
a report that matches the client entity. The client stores it through the normal
outbox, so reports also work offline after generation.

### Device integration

- **Android OCR**: Google ML Kit text recognition on a captured/gallery image,
  with layout-aware line reconstruction so two-column receipts keep their
  label/amount pairs.
- **Web OCR**: manual paste fallback, because ML Kit is native-only.
- **Biometrics**: `local_auth` gate on resume when enabled in settings.
- **Notifications**: budget threshold, unusual-spend, and recurring reminders via
  `flutter_local_notifications`, including reboot rescheduling.
- **Sharing/files**: `share_plus` and `file_saver` for PDF/CSV exports and receipt
  attachments.

---

## Design system

- Dark charcoal and warm ivory, with gold/amber as the case-file accent and coral
  for evidence/alert states.
- Instrument Serif for editorial headlines; Plus Jakarta Sans for UI and money.
- Shared surfaces (`AppCard`, `DossierHeader`, `CaseStamp`, `MetricTile`), control
  primitives, and responsive breakpoints at 700/980/1440 px.
- Dossier language is structural rather than decorative: navigation, empty states,
  budget alerts, chat, export headers, and the AI report all use the same metaphor.
- All interactive controls have web/desktop hover states, keyboard focus, and
  semantic labels where Flutter provides them.

---

## Tests and CI

```bash
flutter test
flutter test --coverage
```

Coverage includes:

- Receipt parsing (merchant, total, dates, line items, empty OCR text).
- Category classification (coffee, transport, bills, fallback).
- Wallet balances with transfers, monthly totals, cash flow, budget thresholds.
- Category/merchant ranking and anomaly detection.
- Money formatting/parsing, hidden amounts, and recurring date arithmetic.
- Sync engine demo-mode behavior and local-only writes.
- Narrow-width widget layout tests that fail on RenderFlex overflows.

`.github/workflows/ci.yml` runs three jobs on pushes and pull requests:

1. Format check, `flutter analyze`, tests, coverage artifact.
2. Release web build.
3. Release Android APK build.

Both build jobs accept optional `SUPABASE_URL` / `SUPABASE_ANON_KEY` repository
secrets. Without them the artifacts are still valid demo-mode builds.

---

## Security and privacy notes

- Supabase RLS is the authorization boundary; the anon key is never trusted.
- Invite codes are short-lived, rotated per wallet, single-use, and only issued to
  owners/editors.
- Android backup is disabled so local receipts are not copied to cloud backup.
- Receipts live in a private storage bucket under `<user-id>/...` with owner-only
  policies and seven-day signed URLs for other wallet members.
- The app clears local case data on sign-out. Pending offline changes are expected
  to be synced before signing out.
- AI requests contain aggregated amounts, category names, and merchant labels;
  receipt raw text and case-note bodies are not sent.

---

## Known limitations

- A live Supabase project is required to verify cloud auth, RLS, realtime, storage,
  and Edge Function behavior end to end. The app is fully exercisable in demo mode.
- Custom categories are personal by default. If a shared wallet uses someone
  else's custom category, the other member will see it as uncategorized.
- Web OCR is paste-based by design; native Android uses ML Kit.
- The Android release build uses the local `android/app/debug.keystore` when it
  exists, and otherwise falls back to the Flutter debug key. This keeps
  evaluation builds installable; add a dedicated release keystore before
  publishing to a store.
- Free-tier AI models and quotas change. `AI_MODEL` and `AI_BASE_URL` are
  configurable, and the heuristic fallback keeps reports available.

---

## Credits

Built with Flutter, Supabase, Hive CE, BLoC, go_router, fl_chart, Google ML Kit,
and the Instrument Serif / Plus Jakarta Sans typefaces. Product copy and case-file
language are original to Dompetektif.
