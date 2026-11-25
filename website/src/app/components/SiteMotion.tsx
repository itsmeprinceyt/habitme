"use client";

import { useEffect, useLayoutEffect, useSyncExternalStore } from "react";
import gsap from "gsap";

const useIsomorphicLayoutEffect =
  typeof window !== "undefined" ? useLayoutEffect : useEffect;

const subscribeToHydration = () => () => {};

const REVEAL_SELECTOR = "[data-reveal], [data-feature-card]";

/**
 * Deliberately simple GSAP motion:
 *   1. a short hero intro, always played on mount
 *   2. a fade/slide reveal for `[data-reveal]` and `[data-feature-card]`
 *      targets as they enter the viewport
 *
 * No ScrollTrigger, no start/end maths, no animation on the footer or on
 * page shells — content can never get stuck invisible. Reduced motion skips
 * everything and leaves the page static.
 */
export function SiteMotion() {
  // False while React hydrates, true afterwards. GSAP must not write inline
  // styles onto server-rendered nodes during hydration.
  const hydrated = useSyncExternalStore(
    subscribeToHydration,
    () => true,
    () => false,
  );

  useIsomorphicLayoutEffect(() => {
    if (!hydrated) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    let observer: IntersectionObserver | null = null;

    const show = (targets: Element[]) => {
      if (targets.length === 0) return;
      gsap.to(targets, {
        opacity: 1,
        y: 0,
        duration: 0.65,
        ease: "power2.out",
        stagger: 0.06,
        overwrite: "auto",
        onComplete: () => gsap.set(targets, { clearProps: "opacity,transform" }),
      });
    };

    const context = gsap.context(() => {
      // Hero intro.
      gsap
        .timeline({ defaults: { ease: "power3.out", duration: 0.8 } })
        .from("[data-anim='hero-badge']", {
          y: 14,
          opacity: 0,
          duration: 0.55,
        })
        .from("[data-anim='hero-title']", { y: 22, opacity: 0 }, "-=0.35")
        .from("[data-anim='hero-copy']", { y: 16, opacity: 0 }, "-=0.5")
        .from("[data-anim='hero-actions']", { y: 14, opacity: 0 }, "-=0.45")
        .from(
          "[data-anim='hero-metric']",
          { y: 18, opacity: 0, stagger: 0.06, duration: 0.65 },
          "-=0.4",
        );

      const targets = gsap.utils.toArray<HTMLElement>(REVEAL_SELECTOR);

      // Anything already on screen shows up immediately.
      const inView: HTMLElement[] = [];
      const below: HTMLElement[] = [];

      targets.forEach((target) => {
        if (target.getBoundingClientRect().top < window.innerHeight * 0.95) {
          inView.push(target);
        } else {
          gsap.set(target, { opacity: 0, y: 22 });
          below.push(target);
        }
      });

      show(inView);

      if (below.length === 0) return;

      if (typeof IntersectionObserver === "undefined") {
        show(below);
        return;
      }

      observer = new IntersectionObserver(
        (entries) => {
          const entered: Element[] = [];
          entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            observer?.unobserve(entry.target);
            entered.push(entry.target);
          });
          show(entered);
        },
        { threshold: 0 },
      );

      below.forEach((target) => observer?.observe(target));
    });

    return () => {
      observer?.disconnect();
      context.revert();
    };
  }, [hydrated]);

  return null;
}
