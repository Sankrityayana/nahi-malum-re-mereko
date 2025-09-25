# Speech Practice App (Flutter + Supabase)

A bilingual (Hindi + English) speech practice app with on-device TTS/STT, gamification (streaks, coins, badges), leaderboard, and a Supabase backend.

• Flutter front-end with Material 3, Google Fonts, animated feedback, and friendly UX.
• Free speech stack by default (no paid APIs): device TTS/STT, optional local recording.
• Secure backend with Supabase Auth, RLS policies, Storage, and SQL functions.

---

## Table of Contents
1. Features
2. Architecture overview
3. Prerequisites
4. Supabase setup (DB + policies + storage)
5. App setup (Flutter create, dependencies, env)
6. Run the app (Windows/Android/iOS)
7. Speech engine notes (free options)
8. Database schema (tables, RPCs, policies)
9. Storage and privacy (public vs signed URLs)
10. Testing
11. Troubleshooting / FAQ
12. Roadmap

---

## 1) Features
- Auth: Email/password with Supabase Auth
- Practice: random words (Hindi/English), TTS playback, on-device STT, similarity scoring, motivational feedback
- Gamification: streaks, coins, cloud-synced stats; animated badge unlock popup
- Leaderboard: global ranking by accumulated score
- Profile: real progress graph, earned badges, next-badge progress hints
- Recording: optional on-device audio capture and upload to Supabase Storage (long-press Record)

---

## 2) Architecture overview
- Frontend: Flutter 3.x, Material 3 UI, Google Fonts, fl_chart for graphs
- Speech:
  - TTS via `flutter_tts` (device voices: hi-IN / en-IN)
  - STT via `speech_to_text` (device speech engine)
- Backend: Supabase (Auth, Postgres + RLS, Storage, SQL RPCs)
- Data flow: Client reads words via an RPC, saves practice progress to Postgres, updates user_stats (streak/coins), awards badges server-side, shows unlock dialog

---

## 3) Prerequisites
- Flutter 3.x (Dart SDK 3.5+)
- Android Studio (Android), Xcode (iOS), or Windows Desktop
- Supabase project (free tier): https://supabase.com

---

## 4) Supabase setup (DB + policies + storage)
1) Create a Supabase project (free tier).
2) In the SQL Editor, run the SQL files in this order:
   - `supabase/schema.sql` (creates tables, policies, RPCs)
   - `supabase/seed_words.sql` (sample Hindi/English words)
3) Storage: create a bucket `recordings`.
   - For a quick start: make it public.
   - For privacy (recommended): keep it private and use signed URLs (see Section 9).
4) Find your Project URL and Anon Key under Settings → API.

---

## 5) App setup (Flutter create, dependencies, env)
If platform folders don’t exist yet, generate them once:

```powershell
flutter create .
```

Install dependencies:

```powershell
flutter pub get
```

Provide Supabase credentials (required by `String.fromEnvironment` in `lib/main.dart`):

Option A — pass defines in the run command

```powershell
flutter run -d windows --dart-define SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Android emulator example:

```powershell
flutter run -d emulator-5554 --dart-define SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Option B — use a `.env` file

```env
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Then:

```powershell
flutter run --dart-define-from-file=.env
```

A sample file `.env.sample` is included.

---

## 6) Run the app (Windows / Android / iOS)
- Windows Desktop: use the Windows command above.
- Android: ensure emulator microphone is enabled; grant RECORD_AUDIO permission at runtime.
- iOS: run from Xcode or `flutter run`; ensure Info.plist contains mic + speech permissions.

Platform permissions:

Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

iOS (Info.plist)

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>We use speech recognition to help you practice pronunciation.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice.</string>
```

---

## 7) Speech engine notes (free options)
- TTS: `flutter_tts` uses device/system voices; set locale to `hi-IN` (Hindi) or `en-IN` (Indian English). No keys or billing.
- STT: `speech_to_text` uses device engine; for Hindi accuracy, install/enable Google voice typing + Hindi language pack on Android. On iOS, ensure Siri dictation is available.
- Alternatives (optional):
  - gTTS for TTS in a Supabase Edge Function (cache audio, don’t expose keys in the client)
  - Vosk for offline STT

---

## 8) Database schema (tables, RPCs, policies)
Core tables:
- `words(id, text, lang, difficulty, created_at)`
- `progress(id, user_id, word_id, target_text, score, created_at)`
- `user_stats(user_id, streak, coins, last_practice_date)`
- `badges(code, name, description, icon)`
- `user_badges(user_id, badge_code, earned_at)`

Views / RPCs:
- `leaderboard` view and `get_leaderboard(limit)` RPC
- `get_random_words(lang, limit)` RPC
- `get_progress_stats(user)` RPC (attempts, best, last)
- `compute_and_award_badges(user)` RPC (atomic award + returns newly unlocked badges)

Policies (RLS):
- Words readable by all
- Progress: users can insert/select their own
- user_stats: users can select/insert/update their own
- badges: readable by all; user_badges: users can read/insert their own

---

## 9) Storage and privacy (public vs signed URLs)
Quick start uses a public `recordings` bucket. For privacy:
1) Make bucket private.
2) Create a server-side route (Supabase Edge Function) to generate a signed URL for uploading/reading.
3) In Flutter, call that function to obtain a one-time URL; upload with HTTP PUT.

This keeps audio non-public and time-limited.

---

## 10) Testing
Run unit tests:

```powershell
flutter test
```

Included tests:
- `speech_similarity_test.dart`: checks scoring order
- `gamification_service_test.dart`: streak bump smoke test

---

## 11) Troubleshooting / FAQ
- STT not returning Hindi?
  - Android: Install Hindi language pack and enable Google voice typing.
  - Use locale `hi_IN` in the app.
- Supabase 401 or no data?
  - Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided via `--dart-define` or `.env` file.
  - Ensure you ran `supabase/schema.sql` and have tables with RLS policies.
- Random words not changing?
  - Ensure RPC `get_random_words` exists (created by `schema.sql`).
- Storage upload fails?
  - Confirm `recordings` bucket exists, and it’s public (for quick start) or you’re using signed URLs.
- Windows STT?
  - It’s limited compared to Android/iOS. Prefer running on a mobile emulator/device for best results.

---

## 12) Roadmap
- Signed URLs + RLS for recordings (privacy by default)
- Offline queue for progress and uploads
- Dedicated Badges page and unlock feed
- Phoneme-aware scoring via Edge Function
- Friends leaderboard / social sharing

---

Made with Flutter + Supabase. Contributions and ideas are welcome.