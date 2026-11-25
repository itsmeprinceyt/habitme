# HabitMe Website — Project Structure

> Project-specific documentation. Use this instead of re-reading every file:
> it records how the site is wired, where things live, and what to touch for a
> given change.
>
> Last updated: 25 November 2026

---

## 1. Stack & Commands

- **Next.js 16.4.5** (App Router, Turbopack dev/build)
- **React 19.3**
- **TypeScript 5** (strict, `@/*` → `./src/*`)
- **Tailwind CSS v4** via `@tailwindcss/turbopack` (no `tailwind.config.*`; theme
  is declared inline in `globals.css` with `@theme inline`)
- **lucide-react** for all icons
- **next/image** for the logo
- Deployment: **Vercel** (`vercel.json` only builds `main`; other branches are
  skipped). No API routes, no server actions, no database, no env vars.

```bash
cd website
npm install          # or bun install
npm run dev          # next dev (default port 3000)
npm run build        # next build
npm run lint         # eslint (currently fails on a pre-existing hook warning)
npx tsc --noEmit -p tsconfig.json   # typecheck; this is the reliable gate
```

Notes:
- `next dev` in this project does **not** accept `--host`; options are parsed by
  Next itself. Use `--port` if needed.
- `next.config.ts` enables `devIndicators: false`, `cacheComponents`,
  `partialPrefetching`, and registers the Tailwind Turbopack CSS rule.
- Some files are CRLF; the edit tools handle mixed newlines, but keep diffs
  focused.

---

## 2. File Tree

```
website/
├─ package.json                 scripts + deps (next, react, lucide, tailwind v4)
├─ next.config.ts               Turbopack + caching flags, Tailwind loader rule
├─ tsconfig.json                strict TS, "@/*" -> "src/*", next plugin
├─ eslint.config.mjs            flat config (eslint-config-next)
├─ vercel.json                  deploy only from main
├─ public/
│  ├─ habitme_logo_svg.svg      header/about logo (vector)
│  ├─ habitme_logo.png          source logo
│  ├─ habitme_logo_rounded.png  favicon + in-mockup drawer logo
│  └─ app-ads.txt               ads.txt entry for the ad network
└─ src/
   ├─ assets/docs/              README.md (rules) + Project_Based/ (this file, UI/UX)
   └─ app/
      ├─ layout.tsx             fonts, global metadata, html/body shell
      ├─ globals.css            Tailwind import, theme vars, scrollbar, focus, motion
      ├─ page.tsx               "/" — client page, holds demo state + header/footer
      ├─ privacy/page.tsx       "/privacy" — LegalPage + Privacy Policy sections
      ├─ terms/page.tsx         "/terms" — LegalPage + Terms & Conditions sections
      └─ components/
         ├─ HeroSection.tsx     hero copy, CTAs, 4 metric cards
         ├─ DemoSection.tsx     phone mockup + all in-app sub-components (~1460 lines)
         ├─ FeaturesSection.tsx three feature cards
         ├─ AboutSection.tsx    "Why HabitMe Exists" story + download CTA card
         ├─ SiteHeader.tsx      shared sticky header for legal pages
         ├─ SiteFooter.tsx      shared footer (all pages) incl. legal links
         ├─ LegalPage.tsx       legal shell + TOC + section cards
         └─ utils/GithubIcon.tsx inline GitHub SVG (lucide has no brand icon)
```

---

## 3. Routes

| Route | File | Type | Purpose |
| --- | --- | --- | --- |
| `/` | `src/app/page.tsx` | client (`"use client"`) | Landing page with interactive demo |
| `/privacy` | `src/app/privacy/page.tsx` | server | Privacy Policy (metadata + `LegalSection[]`) |
| `/terms` | `src/app/terms/page.tsx` | server | Terms & Conditions (metadata + `LegalSection[]`) |

No dynamic routes, no route groups, no loading/error files, no middleware.

---

## 4. Data & State Flow

There is no backend. Everything is in-memory.

```
page.tsx (client, owns state)
 ├─ habits: MockHabit[]            seed array of 6 demo habits, dates in Nov 2026
 ├─ nextOccurrence(habit)          +1 day, rebuilds dueAt + dueLabel
 ├─ toggleHabit(id)                recurring -> isDone true + rolled date;
 │                                 one-time -> simple toggle
 ├─ addHabit(input)                prepends a custom habit (custom-<timestamp>)
 ├─ updateHabit(id, input)         merges NewHabitInput
 └─ deleteHabit(id)                removes
        │
        ├─ <HeroSection …>                  static copy + anchors
        ├─ <DemoSection habits=… handlers=…> renders list/calendar/drawer/form
        ├─ <FeaturesSection />              static
        └─ <AboutSection />                 static
```

`DemoSection` exports the shared types used by `page.tsx`:

```ts
type HabitType = "recurring" | "one-time";

interface MockHabit {
  id: string; name: string; type: HabitType;
  recurrenceLabel: string; isDone: boolean;
  labelId: string | null; notify: boolean;
  dueAt?: string; dueLabel?: string; completedLabel?: string;
  days?: number[];            // Nov 2026 days for the heatmap
}

interface NewHabitInput {
  name: string; type: HabitType; labelId: string | null;
  recurrenceLabel: string; notify: boolean;
}
```

DemoSection internal pieces (top to bottom in the file):

1. Types + `DEMO_LABELS` palette
2. `C` (in-app colours), `themeVars` (`--hm-*`), `RAISED_SHADOW*`
3. Helpers: `tint`, `hexToRgb`, `isLightFill`, `formatCountdown`, `useTick`, `labelFor`
4. `AppSwitch`, `SectionHeader`, `LabelSubheader`
5. `HabitTile` (expand + countdown + per-habit actions)
6. `HeatDay`, `CalendarView` (November 2026 constants `MONTH_TITLE`,
   `FIRST_WEEKDAY_INDEX = 6`, `DAYS_IN_MONTH = 30`, `TODAY = 24`)
7. `PRESETS`, `recurrenceText`, `HabitForm` (create/edit dialog)
8. `DemoSection` (section wrapper, phone frame, status bar, app bar, drawer,
   list/calendar switch, FAB, form mount)

In the mockup, "Active" = `!isDone`, "Completed" = `isDone`; grouping is by
`labelId`, labels sorted A→Z, unlabelled last. Section/group collapse state is
local to `DemoSection`.

---

## 5. Shared Layout Components

### `SiteHeader` (`components/SiteHeader.tsx`)
Props: `{ active?: "privacy" | "terms" }`. Sticky, blurred, `border-b`, mirrors
the landing header: logo + "Keep the habit alive." badge, Home / Features /
Privacy / Terms, Download APK button. Used only by legal pages.

The landing page keeps its **own** header inside `page.tsx` because its links use
`scrollTo(ref)` instead of hash navigation.

### `SiteFooter` (`components/SiteFooter.tsx`)
No props. Links: itsmeprince.com, GitHub Release, `/#features`, `/#demo`,
`/privacy`, `/terms`; copyright below. Used by `page.tsx` and `LegalPage`.

### `LegalPage` (`components/LegalPage.tsx`)
Props:
```ts
{ active: "privacy" | "terms"; eyebrow: string; title: string;
  intro: string; updated: string; sections: LegalSection[] }
interface LegalSection { id: string; title: string; body: React.ReactNode }
```
Renders glow, header, back link, eyebrow pill, H1, intro, updated date, numbered
"On this page" TOC, section cards (`id` anchors), closing note, footer.
The `body` slot uses a scoped arbitrary-variant class string for prose styling
(links, strong, ul), so new sections get the right typography automatically.

**To add a legal section:** append `{ id, title, body }` to the `sections` array
in the relevant page — TOC and anchors update on their own.

---

## 6. Styling System

- Tailwind v4: `globals.css` starts with `@import "tailwindcss";` then
  `@theme inline` maps `--color-background`, `--color-foreground`, `--font-sans`,
  `--font-mono`. No config file.
- Most component styling uses **arbitrary hex utilities** (`bg-[#0D0D0D]`,
  `text-[#8A8A8A]`, `border-[#262626]`). There is no shared token module for the
  marketing palette — when changing a global colour, search the hex.
- `body` forces black background + white text + `overflow-x-hidden`; selection
  colours and scrollbar are customised globally.
- Motion respects `prefers-reduced-motion`.
- Root layout sets `dark` class and flex column body; pages provide their own
  `min-h-screen flex flex-col` wrapper.
- Metadata: global in `layout.tsx`; each legal page exports its own `metadata`
  (title/description) which replaces the layout title for that route.

---

## 7. Where To Change What

| Task | File(s) |
| --- | --- |
| Hero headline/copy/metrics | `components/HeroSection.tsx` |
| Header nav, badge, download CTA (landing) | `app/page.tsx` |
| Header for legal pages | `components/SiteHeader.tsx` |
| Footer links/copyright | `components/SiteFooter.tsx` |
| Feature cards | `components/FeaturesSection.tsx` |
| "Why HabitMe Exists" story, final CTA | `components/AboutSection.tsx` |
| Demo section intro text | `DemoSection.tsx` → `DemoSection` return block |
| Seed habits / rollover logic | `app/page.tsx` |
| Mockup visuals/labels/calendar/form | `components/DemoSection.tsx` |
| Privacy policy content | `app/privacy/page.tsx` (`sections` array) |
| Terms content | `app/terms/page.tsx` (`sections` array) |
| Legal page shell (TOC, cards, back link) | `components/LegalPage.tsx` |
| Site title/favicon/description | `app/layout.tsx` |
| Global colours/scrollbar/focus | `app/globals.css` |
| Build/Tailwind/Turbopack config | `next.config.ts` |

### Repeated constants (keep in sync manually)
- GitHub releases URL `https://github.com/itsmeprinceyt/habitme/releases` is
  duplicated in `page.tsx`, `SiteHeader.tsx`, `SiteFooter.tsx` and
  `HeroSection`/`AboutSection` (passed as prop from `page.tsx`).
- Colours are duplicated across components by design of the arbitrary-value
  approach; there is no central palette map for marketing surfaces.
- Contact links in legal pages: `https://www.itsmeprince.com` and
  `https://github.com/itsmeprinceyt/habitme/issues`.

---

## 8. Assets & Metadata

- Logos live in `public/` and are referenced with root-relative paths
  (`/habitme_logo_svg.svg`, `/habitme_logo_rounded.png`) through `next/image`
  with explicit `width`/`height`.
- Favicon configured in `layout.tsx` metadata (`/habitme_logo_rounded.png`).
- `public/app-ads.txt` is served as-is for ad-network verification — do not
  delete it.
- No Open Graph / Twitter images are configured yet; adding them means extending
  `metadata` in `layout.tsx`.

---

## 9. Related App Repo (context, not code)

`app/` is the Flutter Android app this site promotes. Useful anchors when copy
must stay truthful:
- `lib/core/constants/app_constants.dart` — app tagline, DB name, Unity ad IDs
- `lib/core/ui/drawer/guide_page.dart` — canonical "Why HabitMe Exists" story and
  the 60-reminder explanation
- `android/app/src/main/AndroidManifest.xml` — declared permissions (notifications,
  exact alarms, wake lock, vibrate, boot, INTERNET for ads)
- `lib/data/services/ads_service.dart` — Unity Ads integration
- `lib/data/services/backup_service.dart` — SQL export/import

---

## 10. Current Health

- `npx tsc --noEmit -p tsconfig.json` → passes.
- `npx eslint src` → **1 pre-existing error**: `react-hooks/set-state-in-effect`
  in `DemoSection.tsx` `useTick` (line ~175). Not introduced by recent work; the
  fix would be restructuring the ticking effect, not suppressing the rule.
- No tests, no CI beyond Vercel's build, no analytics.
- Both `/privacy` and `/terms` render as static server components; `/` is the
  only client page and hydrates the whole demo.
