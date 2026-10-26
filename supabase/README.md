# Dompetektif · Supabase backend

This folder contains the production schema, RLS policies, invite RPCs, storage
policies, realtime publication, and the `investigation-report` Edge Function.

## 1. Create and link a project

```bash
supabase login
supabase link --project-ref <project-ref>
supabase db push
```

`202610260001_initial_schema.sql` creates the ten synced tables, membership
helpers, RLS, realtime, receipt storage, and the invite RPCs.
`202610260002_system_categories.sql` seeds the ten global categories with the
same UUIDs used by the local demo.

## 2. Auth providers

In **Authentication → URL Configuration** add:

- Site URL: your web deployment, for example `https://dompetektif.example.com`
- Additional redirect URLs:
  - `http://localhost:8080`
  - `dev.dompetektif://login-callback`

Enable **Email** (email/password) and **Google**. For Google, add the callback
URL shown by Supabase to the Google Cloud OAuth client. The Android manifest
already registers `dev.dompetektif://login-callback`.

## 3. AI report function

The Edge Function uses the caller's JWT for RLS-scoped queries. It never uses
the service-role key and does not write to the database; the client persists the
returned report through its offline outbox.

Deploy:

```bash
supabase functions deploy investigation-report
```

Set a free-tier, OpenAI-compatible provider (OpenRouter is the default):

```bash
supabase secrets set \
  AI_API_KEY=<free-tier-key> \
  AI_MODEL=google/gemini-2.0-flash-exp:free
# Optional custom OpenAI-compatible endpoint:
# supabase secrets set AI_BASE_URL=https://openrouter.ai/api/v1
```

Without `AI_API_KEY` the function returns a deterministic heuristic report, so
the UI and report history still work. The function includes a 25 second timeout;
the client tolerates either `source: "ai"` or `source: "heuristic"`.

## 4. Storage

The migration creates the private `receipts` bucket. Objects live at
`<user-id>/<receipt-id>.jpg`, and storage RLS only allows the owner to read or
write. Receipt rows are visible to members of a shared wallet; the client stores
a seven-day signed URL for cross-device viewing.

If signed URLs expire, open the receipt on the uploader's device to refresh the
URL, or extend the signed URL duration in
`SupabaseCloudGateway.uploadReceipt`.

## 5. Realtime and offline sync

All synced tables are added to `supabase_realtime`. The app subscribes to
postgres changes and pulls rows ordered by `updated_at`; Hive is the local source
of truth, and an outbox replays writes after connectivity returns.

Server triggers prevent `updated_at` from regressing because of device clock
skew. Conflicting writes use last-write-wins. Deletes use a `deleted_at`
timestamp for syncable content, except `wallet_members`, which is a hard delete.

## 6. RLS model

- `wallets`: owner, editor, or viewer can read; owner/editor can update.
- `wallet_members`: members can read the roster; only the owner can manage it.
- `transactions`, `recurring_rules`, `case_notes`: visible to wallet members,
  writable by owner/editor. Notes must be authored by the signed-in user.
- `budgets`: owner or shared-wallet members; owner/editor can write.
- `receipts`/`reports`: owner or members of the linked wallet.
- `categories`: global system rows plus the caller's own custom rows.
- Invite RPCs are `security definer` with explicit auth checks; invite rows have
  no direct client access.

## 7. Local development

```bash
supabase start
supabase db reset
supabase functions serve investigation-report --env-file ./supabase/.env.local
```

Create `supabase/.env.local` with `AI_API_KEY` for local AI responses. It is
ignored by git.
