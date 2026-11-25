# HabitMe Website — UI / UX Guide

> Project-specific documentation. Mirrors the visual system and interaction
> patterns used in `website/src`. If a change contradicts this file, either the
> change or this document is wrong — reconcile them deliberately.
>
> Last updated: 25 November 2026

---

## 1. Design Intent

The website sells one idea from the app: **habits break when you take a break,
and HabitMe keeps the habit alive.**

Everything on screen should feel:

- **Calm and dark** — no bright panels, no gradient noise. A black canvas with
  a single soft green glow and flat cards.
- **Precise** — small type for labels, uppercase micro-labels, monospace for
  technical details, tabular numbers for counters.
- **Honest** — copy never claims more than the app does. Habit data is local, but
  the app is ad-supported and therefore has network access; the UI says
  "no account / no cloud sync", not "zero network permissions".
- **Touchable** — the phone mockup is a real interactive toy, not a screenshot.

Primary audience: someone landing from GitHub releases or the app drawer who
wants to know what the app is, see it, and download the APK.

---

## 2. Colour System

### Marketing surfaces

| Token | Value | Usage |
| --- | --- | --- |
| Page background | `#000000` | `body`, all marketing sections |
| Ambient glow | `rgba(34,197,94,0.12)` | Fixed radial gradient at top of the page |
| Card / surface | `#0D0D0D` | Feature cards, metric cards, legal cards |
| Inset surface | `#141414` | Icon tiles, secondary buttons, header logo box |
| Hover surface | `#1C1C1C` | Secondary button hover |
| Border | `#262626` | Card and section borders (often at `/80`) |
| Border hover | `#383838` | Feature card hover |
| Primary text | `#FFFFFF` | Headings |
| Muted text | `#8A8A8A` | Body copy, nav links, footer |
| Accent | `#22C55E` | CTAs, badges, icon highlights, links in legal pages |
| Accent hover | `#1EB054` | CTA hover |
| Warning / secondary | `#FF8A00` | Privacy card icon, "Intervals" metric label |
| Demo section band | `#0A0A0A` at 60% | The `#demo` section background between borders |

Selection: green at 20–30% alpha. Scrollbar: `#0D0D0D` track / `#262626` thumb.

### Inside the phone mockup (`DemoSection`)

The mockup intentionally uses its **own** palette (`const C` in
`DemoSection.tsx`) so it can imitate the Flutter app rather than the marketing
site:

| Key | Value | Notes |
| --- | --- | --- |
| `black` | `#0A0E0B` | screen background |
| `surface` | `#141B16` | app bars, drawer |
| `surfaceLight` | `#1F2922` | switch track, chips |
| `card` | `#1A231D` | habit tiles, calendar card |
| `border` / `borderStrong` | `#2E3B32` / `#3E4D42` | dividers, expanded tile gradient |
| `white` | `#EDF3EC` | primary text (slightly green-tinted) |
| `muted` / `faint` | `#8E9C90` / `#5F6E63` | secondary / disabled text |
| `accent` / `accentDeep` | `#2BD673` / `#16A34A` | completion, recurring, FAB gradient |
| `green` | `#86B49A` | notification/pill accents |
| `orange` | `#D9A45B` | one-time habits, completed section |
| `red` | `#E0655F` | "Support developer" heart |

Label palette (also from the app): Health `#2BD673`, Mind `#86B49A`,
Work `#D9A45B`.

The mockup palette is exposed as CSS variables `--hm-*` through `themeVars`, so
children can use `text-[var(--hm-white)]` etc. Keep new mockup code inside that
variable system rather than hard-coding hexes.

---

## 3. Typography

- Fonts: **Geist** (`--font-geist-sans`) and **Geist Mono**
  (`--font-geist-mono`), loaded in `layout.tsx` via `next/font/google`.
- Display headings: `font-extrabold tracking-tight`, scale
  `text-3xl → sm:text-5xl → md:text-7xl` (hero only uses the largest step).
- Section headings: `text-3xl sm:text-5xl` (features) or `text-3xl sm:text-4xl`
  (demo, legal).
- Body: `text-sm sm:text-base` / `text-base sm:text-xl` in the hero, always
  `leading-relaxed`, colour `#8A8A8A`.
- Micro-labels: `text-[10px]–text-xs`, `uppercase`, `tracking-wider` or
  `tracking-[0.18em]`, `font-semibold`.
- Technical footers inside cards: `text-xs font-mono`.
- Countdowns and metric numbers: `tabular-nums` to prevent jitter.

The phone mockup uses a Roboto-ish stack (`Roboto, "Helvetica Neue", Arial`) and
much smaller sizes (`text-[10px]`–`text-[16px]`) because it is a scaled device.

---

## 4. Layout, Spacing & Responsiveness

- Content width: `max-w-7xl` for the header, footer, hero, demo, features and
  legal pages; `max-w-4xl` for legal reading columns; `max-w-2xl/3xl` for
  centred prose.
- Horizontal page padding is always `px-6 sm:px-10`. Never add a section that
  breaks this rhythm.
- Vertical rhythm: hero `pt-16 sm:pt-24 pb-16`, content sections `py-24`,
  demo `py-20`, legal main `pt-14 sm:pt-20 pb-20`.
- Card radius: `rounded-2xl` for small blocks, `rounded-3xl` for large cards,
  `rounded-xl` for buttons, `rounded-full` for pills.
- Borders carry most separation; shadows are reserved for CTAs
  (`shadow-[#22C55E]/20–25`) and the phone frame.
- Breakpoints used: `sm` (badges, inline headline break, 2-col metric grid),
  `md` (desktop nav, 3-col feature grid), plus `grid-cols-1` defaults.
- Desktop nav is hidden below `md`; there is **no mobile menu** — the download
  CTA and logo remain. Adding a mobile menu is an open improvement.
- The phone mockup is fixed at `max-w-[380px]` with a 680px-tall inner screen;
  content inside scrolls (`overflow-y-auto`) while the frame stays put.
- Legal page TOC is `grid-cols-1 sm:grid-cols-2`.

---

## 5. Page Composition

### Home (`/`)

1. **Sticky header** — logo, "Keep the habit alive." badge, nav
   (Features / Interactive UI / Download), "Made by ItsMe Prince", Download APK.
   Nav links smooth-scroll to refs via `scrollTo`.
2. **Hero** — offline/no-account badge, story-led headline
   "Take a break. Don't lose the habit.", supporting paragraph, three CTAs
   (Get Latest Release, Try Live App Mockup, Source Code), then a 4-card metric
   row: Account · Telemetry · Recurrence · Storage.
3. **Interactive demo** (`#demo`) — section badge "App Functionality Sample",
   heading, disclaimer that it is not the final product, and the phone mockup.
4. **Features** (`#features`) — three cards: recurrence resets, no cloud/account,
   SQL dump & restore. Each card has an icon tile, title, body, and a monospace
   footer line with a small icon.
5. **Why + CTA** (`#about`) — "Why HabitMe Exists" story block (two paragraphs)
   followed by the download card with the logo, "Keep the habit alive." headline
   and two buttons.
6. **Footer** — links (itsmeprince.com, GitHub Release, Features, App UI Demo,
   Privacy Policy, Terms & Conditions) above the copyright.

### Legal pages (`/privacy`, `/terms`)

`LegalPage` shell: same glow + sticky `SiteHeader`, then back link, eyebrow pill,
H1, intro, "Last updated" line, an "On this page" index (numbered links), a stack
of section cards, a closing plain-language note, and `SiteFooter`.

Each section card is `p-6 sm:p-8 rounded-3xl bg-[#0D0D0D] border-[#262626]`
with `scroll-mt-24` so anchor jumps clear the sticky header. Inside, paragraphs
stack with `space-y-3`; lists are disc bullets; links are accent green with
hover underline; `<strong>` is white.

---

## 6. Interactive Behaviour (phone mockup)

State lives in `page.tsx` and is passed down; `DemoSection` only renders and
raises events.

- **List view** — two collapsible sections (Active green, Completed orange),
  then habits grouped by label with a `LabelSubheader` per group. Groups are
  sorted alphabetically; unlabelled habits go last. Empty states are plain
  two-line cards.
- **Habit tile** — icon tile, name, recurrence label, label chip, edit pencil,
  completion switch. Tapping the tile expands it; the switch is a separate hit
  target (`event.stopPropagation()`), as is the pencil.
- **Expanded tile** — label row, due date ("Due date" / "Next occurrence" /
  "Scheduled date"), and a live per-second countdown while expanded only.
  Countdown re-reads `Date.now()` every tick, drops leading zero units, and turns
  orange with "Overdue by …" when late or "Due now" at zero. Completed one-time
  habits show "Completed at" instead of a countdown. Notification-enabled habits
  show a green "Notifications enabled for this habit" line.
- **Completion** — toggling a recurring habit marks it done *and* rolls its due
  date forward one day (mirrors the app's rollover), so the switch never sticks
  on a recurring habit. One-time habits simply toggle and, when done, get a
  strikethrough.
- **Calendar view** — November 2026 heatmap (Monday-first offset 6, 30 days,
  today = 24). Heat alpha scales with habit count and caps out; today gets a green
  glow ring; selected day gets a white ring. Below: two filter pills
  (One-Time / Recurring) with `aria-pressed`, and a day detail card listing
  recurring then one-time habits for that day, each with toggle + edit actions.
- **Drawer** — 82% width panel with app logo, "Your Day. Your Habits." tagline,
  menu rows (Guide, Manage Labels, Logs, Import, Export, Support developer) that
  close the drawer, and a "Made by ItsMe Prince" card linking out.
- **New / Edit habit dialog** — centred over the mockup: title field with inline
  validation ("Please name your habit"), label chips (None + the three demo
  labels), Recurring / One-Time cards, presets (Daily, Weekly, Monthly,
  Every 2 days, Hourly), interval + unit selectors for recurring, reminder
  toggle, and Save / Delete / Cancel behaviour.
- **FAB** — bottom-right pill "New habit" with an accent gradient and hover scale.

Because it is a promo replica, actions like Guide, Labels, Logs, Import and
Export in the drawer only close the panel — they do not navigate.

---

## 7. Motion

- Subtle only: `transition-colors` on links, `transition` + `shadow` on buttons,
  `animate-pulse` on the hero availability dot, drawer/section chevrons rotating
  180°, switch knob translating, FAB `hover:scale-[1.03]`.
- `prefers-reduced-motion: reduce` in `globals.css` collapses animation and
  transition durations to ~0.
- No parallax, scroll-reveal libraries, or entrance animations. Keep it that way
  unless the user explicitly asks.

---

## 8. Accessibility & Interaction Rules

- Every icon-only control has an `aria-label` (menu, calendar toggle, edit,
  toggles, day buttons, month arrows).
- Switch buttons use `role="switch"` + `aria-checked`; filter pills use
  `aria-pressed`.
- Global `:focus-visible` outline is a 2px green outline with 2px offset.
- Interactive tiles are clickable `<div>`s (mouse/touch); inner controls are real
  buttons. If you extend the mockup, prefer adding keyboard handlers rather than
  more clickable divs.
- Muted `#8A8A8A` on `#0D0D0D` is the established body contrast — don't lighten
  body text to pure white for "emphasis"; use `<strong>` or a heading instead.
- Images need `alt` text; the logo always uses "HabitMe Logo" or "HabitMe".

---

## 9. Copywriting Rules

- Lead with the story: repeat → break → distortion → recovery. Keep the app's
  exact framing ("obedient to your goals and your own betterment").
- Use the app's tagline **"Keep the habit alive."** as the recurring brand line.
- Sentence case for headings except proper nouns. No exclamation marks except
  the existing "Important Note" style inside the phone.
- Never claim "100% offline", "zero network permissions" or "zero data
  collection" — ads require internet and Unity Ads processes ad data. Use
  "no account", "no cloud sync", "your habit data stays on your device".
- Dates in the site copy are formatted like `Tue, 24 Nov 2026 · 07:00 AM`; keep
  that middot format inside the mockup.
- Legal pages use plain-English headings and explicit "we do not / you can"
  statements; avoid legal jargon where a short sentence works.

---

## 10. Known Issues / Watch-outs

- `DemoSection.tsx` `useTick()` triggers `react-hooks/set-state-in-effect`
  (`setNow(...)` called synchronously in an effect). This is pre-existing and
  makes `npx eslint src` fail; the typecheck and the running site are unaffected.
- The phone drawer tagline still reads "Your Day. Your Habits." while the site
  header uses "Keep the habit alive." Decide one brand line before changing
  either.
- There is no mobile navigation menu; on narrow screens the nav links disappear.
- The mockup is entirely client-side; it has no persistence and resets on reload.
