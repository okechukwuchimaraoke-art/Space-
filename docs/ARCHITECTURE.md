# SPACE Architecture (Phase 1)

- Clients: Flutter (mobile/desktop), Next.js (web). Both talk only to Supabase using the anon key and the user's session.
- Backend: Supabase Postgres with Row Level Security on every table, Auth, Realtime, Storage, Edge Functions.
- Calls: LiveKit (Phase 7). Push: FCM + APNs (Phase 4).
- Secrets (service_role, LiveKit secret, push keys) live only in Edge Functions / CI secrets. Never in client code.
- Messages table stores ciphertext (bytea) only. Clients encrypt before upload.

## Phases
1 Architecture/setup/branding · 2 UI foundation · 3 Auth/profiles · 4 Messaging · 5 E2EE · 6 Media · 7 Calls · 8 AI/social · 9 Multi-device · 10 Test/deploy
