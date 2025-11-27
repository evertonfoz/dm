# Supabase init & debug prompt

Context
-------
During local testing we observed the app printing that Supabase was initialized, but code that accessed `SupabaseService().client` threw `Supabase not initialized. Call initialize first.`. The root cause was a mismatch in initialization flow: `Supabase.initialize(...)` was being called directly in `main.dart`, while the project's wrapper (`SupabaseService`) kept its internal `_client` null and threw on access.

What I changed
--------------
- `SupabaseService.client` now attempts to adopt `Supabase.instance.client` when `_client` is null. This makes the wrapper tolerant to both flows (SDK initialized in `main` or via the wrapper `initialize`).
- Added debug-only prints (`kDebugMode`) in:
  - `SupabaseProvidersRemoteDatasource.fetchProviders`
  - `ProvidersRepositoryImpl.syncFromServer`
  - `SupabaseProvidersRemoteDatasource.upsertProviders` (already had prints)

Why this helps
-------------
- Prevents a misleading exception when the SDK is initialized in `main.dart` and code elsewhere tries to access the wrapper's `client`.
- Debug prints give visibility into whether the sync and upsert flows are being executed in the app and what the remote response/error looks like. They run only in debug builds.

How to test (quick)
--------------------
1. Rebuild app (full restart):

```bash
flutter clean
flutter pub get
flutter run -d <device>
```

2. Observe console for these debug lines (in debug builds):
- `SupabaseProvidersRemoteDatasource.fetchProviders: since=... limit=... offset=...`
- `ProvidersRepositoryImpl.syncFromServer: starting`
- `SupabaseProvidersRemoteDatasource.upsertProviders: sending X items`
- `Supabase upsert response error: ...`
- `Supabase upsert response data length: ...`

3. If you don't see `upsert` prints, ensure you have local cache items by adding a provider in the UI (the UI triggers sync after adding). Pull-to-refresh also triggers sync.

If upsert fails
---------------
1. Run a direct REST test to check anon key + RLS behavior:

```bash
# replace <ANON> and <URL>
curl -s -H "apikey: <ANON>" -H "Authorization: Bearer <ANON>" \
  "<URL>/rest/v1/providers?select=*&limit=1"

# Try an insert (for testing only):
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "apikey: <ANON>" \
  -H "Authorization: Bearer <ANON>" \
  -H "Prefer: return=representation" \
  -d '{"id":-999,"name":"test","updated_at":"2025-11-27T00:00:00Z"}' \
  "<URL>/rest/v1/providers"
```

2. If the REST insert returns 401/403 or a `permission denied` style error, the cause is RLS/policies. For quick testing you can create an `INSERT`/`UPDATE` policy for role `anon` with `USING (true)` (NOT recommended for production). Better: create policies that require authentication and test with an authenticated user.

Notes & security
----------------
- Never commit service role keys into client `.env` (they must stay on server/CI). We removed `SUPABASE_KEY` from the client `.env` and replaced it with `SUPABASE_ANON_KEY` in this workspace.
- Debug prints use `kDebugMode` to avoid noise in release builds.

Next steps (if you want me to continue)
--------------------------------------
- Add an explicit `SupabaseService.adoptSdkClient()` helper and call it in `main` right after `Supabase.initialize(...)` for clarity.
- Add a temporary UI test button that forces `repo.syncFromServer()` so you can trigger sync deterministically from the running app.
- If `response.error` contains RLS or column-mismatch hints, paste it here and I'll produce exact policy changes or DTO -> table mapping fixes.
