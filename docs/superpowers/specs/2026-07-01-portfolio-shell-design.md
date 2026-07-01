# Design Portfolio Shell — Design Doc

**Date:** 2026-07-01
**Status:** Approved (pending spec review)

## Goal

Recreate the "shell" of a split-screen portfolio in the style of
[narinkim.com](https://www.narinkim.com/): a fixed left panel with identity + navigation,
and a scrolling right panel that holds all content. Unlike the reference, the right-panel
work listing uses **full-width list panels**, not a grid. Built for both desktop and mobile.

The right panel focuses on **4 major case studies** the user can click into. Below them, a
small subheading divider introduces a **grid of past designs**. Additional pages (Info,
Contact) reuse the same shell and swap only the right panel.

## Non-Goals

- Real case-study content, copy, or final images (realistic placeholders only).
- A CMS or backend. Content is local files (markdown + Astro).
- Animations/transitions beyond subtle hover states.
- The live clock / timestamp element from the reference (explicitly skipped).

## Tech Stack

- **Astro** (static site generator). Rationale: content-focused, ships minimal JS, first-class
  markdown content collections for case studies, simple hosting.
- Plain CSS (scoped Astro `<style>` + a small global stylesheet with design tokens). No CSS
  framework — the aesthetic is minimal and hand-tunable.
- No client JS required for the shell (mobile nav can use a CSS-only/`<details>` pattern).

## Layout Behavior

**Desktop (≥768px):**
- Two-column split. Left panel fixed/sticky (~32% width, min ~320px), does not scroll.
- Right panel scrolls independently and contains all page content.

**Mobile (<768px):**
- Left panel collapses to a top header (name + nav). Right-panel content stacks below it.
- The whole page scrolls as one column.

```
DESKTOP                     MOBILE
┌──────┬───────────┐        ┌───────────┐
│ name │  panel    │        │  header   │
│ bio  │  panel    │        ├───────────┤
│ nav  │  panel    │        │  panel    │
│      │  panel    │        │  panel    │
└──────┴───────────┘        └───────────┘
(left fixed, right scrolls)  (stacked, page scrolls)
```

## Left Panel (persistent on every page)

- Name / wordmark
- Short bio (2–4 lines, placeholder)
- Nav links: `Work` (→ `/`), `Info` (→ `/info`), `Contact` (→ `/contact`). Active link highlighted.
- Footer: static email + social links (e.g. `email ↗  linkedin ↗`). No live clock.

The left panel is identical across all routes; only the right panel changes.

## Pages & Routes

| Route            | Right-panel content                                                              |
|------------------|----------------------------------------------------------------------------------|
| `/`              | 4 full-width case-study panels (list), then a small subheading divider, then a grid of past designs |
| `/work/[slug]`   | Full case study page. Left panel persists; right panel shows the whole study      |
| `/info`          | About page (placeholder)                                                          |
| `/contact`       | Contact page (placeholder)                                                        |

Clicking a full-width case-study panel on `/` navigates to its `/work/[slug]` page.
Grid tiles are placeholder items for now (no destination required yet).

## Components

- **`Layout.astro`** — the split-screen shell; renders `<Sidebar>` + a `<slot />` for the
  right-panel content. Handles the responsive fixed/stacked behavior.
- **`Sidebar.astro`** — name, bio, nav (with active-state), footer links.
- **`CaseStudyPanel.astro`** — one full-width list panel: index (e.g. "01"), title,
  category · year, tagline, and an image placeholder box (correct aspect ratio). Used ×4 on home.
- **`GridItem.astro`** — one archive tile (image placeholder + short label) for the past-designs grid.
- **Content collection** `src/content/case-studies/*.md` — per-case-study frontmatter
  (title, category, year, tagline, order, slug) + body. Home reads this collection to render
  the 4 panels; `/work/[slug]` renders the full body.

## File Structure

```
src/
  layouts/Layout.astro
  components/
    Sidebar.astro
    CaseStudyPanel.astro
    GridItem.astro
  content/
    config.ts                 # content collection schema
    case-studies/
      case-study-01.md
      case-study-02.md
      case-study-03.md
      case-study-04.md
  pages/
    index.astro               # home: 4 panels + divider + grid
    info.astro
    contact.astro
    work/[slug].astro         # full case study
  styles/global.css           # design tokens + resets
public/                       # any static assets
```

## Aesthetic

Minimal, typography-driven, black-on-white (matches the reference):
- Neutral sans typeface, generous whitespace, thin `1px` dividers, no heavy shadows/cards.
- Images rendered as light-gray placeholder boxes with correct aspect ratios and a subtle label.
- Subtle hover states only (underline / slight offset) on panels and links.
- Design tokens in `global.css`: `--fg` (near-black), `--bg` (white), `--muted` (gray),
  `--border`, spacing scale, max content width.

## Success Criteria

1. Desktop shows fixed left panel + independently scrolling right panel.
2. Mobile collapses the left panel to a top header; content stacks and scrolls as one column.
3. Home right panel renders 4 full-width case-study list panels, a small subheading divider,
   then a grid of past-design tiles.
4. Each full-width panel links to a working `/work/[slug]` page that keeps the left panel.
5. `Info` and `Contact` pages exist with placeholder content and the same shell.
6. All content is realistic placeholder text/images, easy to swap later.
7. Clean minimal black-on-white styling; looks intentional on both breakpoints.

## Open Questions / Later

- Real content, images, and copy.
- Where archive/grid tiles link (individual pages? external?).
- Additional pages beyond Info/Contact.
