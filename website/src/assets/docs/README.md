# DO NOT DO THIS:

- Do not delete/modify any of the files inside the docs folder.
- Always consult the admin user that you wish to update this markdown inside this file.
- All of these files inside the docs are to be assumed READ-ONLY modes.

# `website\src\assets\docs\Project_Based`

- All the files inside this are related to this project we are building. If there is any new file you need to create / modify which is instructed to update by the amdin user you will do in that Project_Based folder because it contains the project specific instructions
- Outisde that, the `website\src\assets\docs` contains the general AI instructions which can be used for anyone again and again in different project. But Project_Based folder contain only the instructions specific to this project.

# Animation & Motion (GSAP)

The website uses **GSAP** (`gsap` in `website/package.json`) as its only animation library. Keep every animation subtle, short and professional — the goal is a premium feel, never a showreel.

- **`website/src/app/components/SiteMotion.tsx`** — one client component rendered at the end of the page content (`page.tsx`, `LegalPage.tsx`), never above it in `layout.tsx`. It waits for hydration (`useSyncExternalStore`) before GSAP writes inline styles, which keeps React's hydration attribute check clean. It owns only the hero intro and the `[data-reveal]` / `[data-feature-card]` reveals.
  - Add `data-reveal` to a section block that should fade/slide in once. Do **not** put it on the footer or on a whole-page wrapper — those must always render.
  - Hero parts use `data-anim='hero-badge' | 'hero-title' | 'hero-copy' | 'hero-actions' | 'hero-metric'`.
  - Keep the motion simple: no ScrollTrigger, no parallax, no start/end position maths.
- **`website/src/utils/scroll.util.ts`** — `smoothScrollToElement` uses GSAP's `ScrollToPlugin` with the sticky-header offset. Use it instead of `scrollIntoView` or raw `window.scrollTo`.
- **Section navigation never uses URL hashes.** The landing page registers its refs in `website/src/utils/section.util.ts`; navbar, footer and legal headers call `scrollToSection("features" | "demo" | "about")`. From another page they `queueSection` then navigate home, and the registration scrolls once the section mounts. Keep new section links on this registry instead of writing `href="#..."`.
- **Legal documents** use `SmoothSectionLink` for their table of contents, which scrolls to the section id without putting a `#` in the address bar.
- **Reveals must never hide content permanently.** `[data-reveal]` / `[data-feature-card]` elements are hidden only when they are below the fold and revealed through an IntersectionObserver + GSAP tween; anything already on screen animates immediately. The footer and legal-page shell are intentionally left out of this system.
- **Reduced motion** — `SiteMotion` exits early and `smoothScrollToElement` uses a zero-duration scroll when `prefers-reduced-motion: reduce` is set. Never add motion that ignores this.
- Do not add a second animation library; extend these files instead.
