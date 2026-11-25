import { smoothScrollToElement } from "./scroll.util";

/**
 * Section navigation without URL hashes.
 *
 * The landing page registers its section elements (features, demo, about) on
 * mount. Any control — navbar, footer, legal header — can then ask for a
 * section by name and get the same GSAP glide, even when it lives outside the
 * page that owns the refs.
 */

export type SiteSection = "features" | "demo" | "about";

const elements = new Map<SiteSection, HTMLElement>();
let pending: SiteSection | null = null;

export function registerSection(
  name: SiteSection,
  element: HTMLElement | null,
): void {
  if (!element) {
    elements.delete(name);
    return;
  }

  elements.set(name, element);

  // Arrived from another page specifically for this section: wait for the
  // next couple of frames (router scroll reset included) and glide to it.
  if (pending === name) {
    pending = null;
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => smoothScrollToElement(element));
    });
  }
}

/** Scrolls now if the section is on screen; returns false if it is not. */
export function scrollToSection(name: SiteSection): boolean {
  const element = elements.get(name);
  if (!element) return false;
  smoothScrollToElement(element);
  return true;
}

/** Remembers the section to scroll to once the landing page mounts. */
export function queueSection(name: SiteSection): void {
  pending = name;
}
