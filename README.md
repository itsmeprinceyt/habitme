# HabitMe

A habit tracker built on a simple idea: we repeat things daily and they become
habits, but a break distorts them. HabitMe helps you keep the habit alive and
stay obedient to your goals and your own betterment.

The project has two parts:

- `app/` - the Android app (Flutter)
- `website/` - the landing site (Next.js)

## Features

- Recurring and one-time habits, with automatic rollover to the next occurrence
- Local reminders with a Done action and a rolling 60-reminder window
- Labels with custom colours, list and calendar views
- Full SQL export and import for backups
- No account and no cloud sync; data stays on the device
- Free and ad-supported

## Run the app

Requires the Flutter SDK.

```bash
cd app
flutter pub get
flutter run
```

Tests and checks:

```bash
flutter analyze
flutter test
```

## Run the website

Requires Node.js 20 or newer.

```bash
cd website
npm install
npm run dev
```

The site is at http://localhost:3000. Build with `npm run build`.

## Docs

- `app/assets/docs/Project_Based/` - app documentation (structure, UI/UX, how it
  works, workflow)
- `website/src/assets/docs/Project_Based/` - website documentation (structure,
  UI/UX)
- `app/assets/PROJECT_DETAILS.md` - earlier app architecture notes

## Links

- Website: https://habitme.vercel.app
- Releases: https://github.com/itsmeprinceyt/habitme/releases
