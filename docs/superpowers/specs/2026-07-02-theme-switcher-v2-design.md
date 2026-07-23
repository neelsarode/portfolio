# Theme Switcher v2 — "Eclipse" morph + circular reveal

**Date:** 2026-07-02 · **Branch:** `style/v2`

## Goal

Replace the two-button dark/light toggle in the sidebar footer with a single
high-end switcher: a morphing sun/moon icon button whose click floods the new
theme across the page as an expanding circle. Preserve the old switcher for a
one-line revert.

## Components

- `src/components/ThemeToggleClassic.astro` — the existing two-button
  switcher, extracted verbatim from `Sidebar.astro`. Kept as the revert path.
- `src/components/ThemeToggle.astro` — the new switcher. Single `<button>`
  pinned to the far right of the sidebar footer (same slot as before).
- `src/components/Sidebar.astro` — imports `ThemeToggle`; reverting means
  importing `ThemeToggleClassic` instead.

## Icon morph

One SVG with shared geometry for both states, animated purely with CSS
transitions keyed off `:root[data-theme]`:

- **Sun → moon:** eight rays retract into the disc; a masking circle slides
  diagonally into the disc, biting it into a crescent; the glyph rotates ~40°
  so the crescent settles tilted.
- **Moon → sun:** the mask slides out and rays pop back with staggered spring
  overshoot (`cubic-bezier(0.34, 1.56, 0.64, 1)`, ~30ms/ray stagger).
- Hover brightens the hairline border and nudges the glyph; press compresses
  the button to 0.92 and springs back; focus uses the global ember outline.

## Page reveal

Click applies the theme inside `document.startViewTransition()`. The default
crossfade is disabled (scoped by a temporary `theme-vt` class on `<html>` so
future view transitions are unaffected); instead the new snapshot is clipped
to a circle expanding from the button center to the farthest viewport corner
(~500ms, ease-out) via WAAPI on `::view-transition-new(root)`.

- **Fallback:** no View Transitions API → plain theme swap with the existing
  color transitions.
- **Reduced motion:** `prefers-reduced-motion: reduce` → skip reveal and
  springs; instant swap.

## Accessibility & contract

- One `<button>` with dynamic `aria-label` ("Switch to light/dark theme") and
  `aria-pressed`; keyboard activation reveals from the button center.
- localStorage key `theme` and the before-paint inline script in
  `Layout.astro` are unchanged.
- Add `color-scheme: dark` / `light` per theme so native UI matches.

## Verification

Drive the toggle both directions in a real browser on the worktree dev server
(port 4323): reveal animation, icon morph, persistence across reload,
keyboard operation, reduced-motion path.
