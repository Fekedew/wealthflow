# WealthFlow

Flutter personal-finance app: income/expenses, budgets, savings goals, charts,
auto-categorization, insights, dark mode, English + Amharic, Ctrl/⌘+K command menu.

## Backend (Supabase)
1. Create a project, then apply `supabase/migrations/20261026000000_init.sql`
   (tables, RLS policies, realtime publication).
2. Auth → Providers → Email: turn **Confirm email** off (no verification).
3. Put your project values in `.env` (already set for the `wealthflow` project; only
   the public URL and publishable key belong there), then just run `flutter run`.
   `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…` overrides `.env`.
Without either the app still runs in guest (local-only) mode.

## How it works
- `lib/data/store.dart`: local cache (shared_preferences) + persistent write queue pushed to Supabase; realtime channel triggers re-sync; reconnect flushes the queue.
- Guest data stays on-device. Signed-in data is isolated per user by RLS.
- Routes are protected by a go_router redirect on auth state.
