# WealthFlow

Flutter personal-finance app: income/expenses, budgets, savings goals, charts,
auto-categorization, insights, dark mode, English + Amharic, Ctrl/⌘+K command menu.

## Backend (Supabase)
1. Create a project, then apply `supabase/migrations/20261026000000_init.sql`
   (tables, RLS policies, realtime publication).
2. Auth → Providers → Email: turn **Confirm email** off (no verification).
3. Run with your project values:

```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key>
```
Without these the app still runs in guest (local-only) mode.

## How it works
- `lib/data/store.dart`: local cache (shared_preferences) + persistent write queue pushed to Supabase; realtime channel triggers re-sync; reconnect flushes the queue.
- Guest data stays on-device. Signed-in data is isolated per user by RLS.
- Routes are protected by a go_router redirect on auth state.
