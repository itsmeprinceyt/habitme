"use client";

import React from "react";
import { smoothScrollToElement } from "../../utils/scroll.util";

interface SmoothSectionLinkProps {
  id: string;
  className?: string;
  children: React.ReactNode;
}

/**
 * In-page jump used by the legal documents' table of contents. It scrolls with
 * the same GSAP glide as the rest of the site and never writes a #hash into
 * the address bar.
 */
export function SmoothSectionLink({
  id,
  className,
  children,
}: SmoothSectionLinkProps) {
  return (
    <button
      type="button"
      className={`text-left ${className ?? ""}`}
      onClick={() => smoothScrollToElement(document.getElementById(id))}
    >
      {children}
    </button>
  );
}
