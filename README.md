# Speech Practice App (Flutter + Supabase)

A bilingual (Hindi + English) speech practice app with TTS, STT, gamification, and Supabase backend.

## Features
- Login/Signup via Supabase Auth
- Practice tricky words/sentences with TTS (hi/en) and STT comparison
- Accuracy feedback and progress saving
- Leaderboard, streaks, and simple graphs

## 1) Prereqs
- Flutter 3.x (Dart SDK 3.5+)
- Android Studio/Xcode for emulators
- Supabase project (free tier)

## 2) Setup Supabase (free)
1. Create a Supabase project: https://supabase.com
2. In SQL Editor, run `supabase/schema.sql` then `supabase/seed_words.sql`.
3. Get Project URL and anon key from Project Settings → API.
4. Storage: create a bucket `recordings` (public or with RLS + signed URLs).

## 3) Create Flutter project structure (once)
If this folder is not an initialized Flutter project yet, generate platform folders:

```
flutter create .
```

This creates `android/`, `ios/`, `web/`, `windows/`, etc. Our `lib/` and `pubspec.yaml` are already provided.

## 4) Configure Flutter app
Set Dart defines at build time (required for `String.fromEnvironment`):

Windows PowerShell examples:

```
flutter run -d windows --dart-define SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

For Android:
```
flutter run -d emulator-5554 --dart-define SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Alternatively, create a `.env` and use `--dart-define-from-file=.env` with contents:
```
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```
Then run:
```
flutter run --dart-define-from-file=.env
```

## 5) Install deps and run
```
flutter pub get
```
Then run as above with env vars.

## 6) Speech (Free options)
- TTS: `flutter_tts` uses platform-native voices (Android/iOS/Windows). Choose locale `hi-IN` or `en-IN`. No cloud cost.
- STT: `speech_to_text` uses on-device speech engine where available. For best Hindi support, enable Google app/voice typing on Android. For iOS, Siri dictation.
- If you need cloud-level accuracy for free-ish:
  - gTTS (Text-to-Speech) is an open-source client for Google Translate TTS, not official. For demos, call in a Supabase Edge Function and cache audio. Avoid shipping keys to clients.
  - Vosk offline STT (no cloud). Add later if needed.

This template defaults to free, on-device engines to avoid API costs.

## 7) Edge Functions (optional)
You can create functions in `supabase/functions` for: word selection, audio analysis, signed URL upload.

Example outline (Deno):
```ts
// supabase/functions/hello/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
serve((req) => new Response(JSON.stringify({ ok: true })));
```
Deploy with Supabase CLI.

## 8) Database
Tables: `words`, `progress`. View+RPC: `leaderboard`, `get_leaderboard`.
RLS enabled so users only read their own progress.

## 9) Next improvements
- Real audio capture + upload to Storage
- More gamification (coins, badges in DB)
- Friends leaderboard (by relationship)
- Edge function for smarter scoring (phoneme distance)

## 10) Troubleshooting & platform notes
- If STT not returning Hindi: check device language packs. Use `hi_IN` locale.
- Supabase 401: ensure env vars are set for this run.
- Android mic permission: add to AndroidManifest. iOS: update Info.plist. See below.
- Windows: `speech_to_text` is best on Android/iOS; on Windows, prefer running Android emulator or add a Windows STT plugin. TTS works on Windows via `flutter_tts`.

### Android permissions
```
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```
Add to `android/app/src/main/AndroidManifest.xml` within `<manifest>`.

### iOS permissions (Info.plist)
```
<key>NSSpeechRecognitionUsageDescription</key>
<string>We use speech recognition to help you practice pronunciation.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice.</string>
```

---
This is a minimal, runnable starter. Extend as needed.