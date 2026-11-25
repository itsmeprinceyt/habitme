import gsap from "gsap";
import { ScrollToPlugin } from "gsap/ScrollToPlugin";

/**
 * GSAP-powered page scrolling.
 *
 * Kept in one place so every in-page link (header, hero button and footer)
 * behaves the same: a short eased glide instead of the browser's instant jump.
 */

let registered = false;

function ensurePlugin() {
  if (registered) return;
  gsap.registerPlugin(ScrollToPlugin);
  registered = true;
}

/** Height of the sticky header, so sections do not land underneath it. */
export const HEADER_OFFSET = 84;

export function prefersReducedMotion(): boolean {
  return (
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  );
}

export function smoothScrollToElement(element: Element | null): void {
  if (!element || typeof window === "undefined") return;
  ensurePlugin();

  const top =
    element.getBoundingClientRect().top + window.scrollY - HEADER_OFFSET;

  gsap.to(window, {
    duration: prefersReducedMotion() ? 0 : 0.9,
    ease: "power3.inOut",
    scrollTo: { y: top, autoKill: true },
    overwrite: "auto",
  });
}

export function smoothScrollToHash(hash: string): void {
  if (typeof document === "undefined") return;
  const id = decodeURIComponent(hash.replace(/^#/, ""));
  if (!id) return;
  smoothScrollToElement(document.getElementById(id));
}
