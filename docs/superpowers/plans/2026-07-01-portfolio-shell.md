# Portfolio Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the shell of a split-screen design portfolio (Astro) — fixed left sidebar, scrolling right panel with 4 full-width case-study list panels + a past-work grid, plus Info/Contact pages and `/work/[slug]` case-study pages.

**Architecture:** One shared `Layout.astro` renders the persistent sidebar + a `<slot />` for right-panel content. Pages under `src/pages/` fill the slot. Case studies are an Astro content collection (markdown) read by the home page (4 panels) and `/work/[slug]` (full body). Minimal black-on-white CSS driven by tokens in a global stylesheet.

**Tech Stack:** Astro (static), plain scoped CSS + one global stylesheet, no client JS, no CSS framework.

## Global Constraints

- Framework: **Astro**, static output. No React/other UI framework.
- No client-side JavaScript for the shell. Mobile nav uses a CSS-only pattern.
- Styling: plain CSS only (Astro scoped `<style>` + `src/styles/global.css`). No Tailwind/other framework.
- Content is **realistic placeholder** text/images. Images are CSS placeholder boxes, no real image files required.
- Aesthetic: minimal, typography-driven, black-on-white. Thin 1px dividers, generous whitespace, subtle hover only. No live clock.
- Breakpoint: **768px**. ≥768px = fixed left / scrolling right; <768px = stacked, page scrolls as one column.
- Design tokens live in `src/styles/global.css` (`--fg`, `--bg`, `--muted`, `--border`, spacing, `--max-w`) and are reused everywhere.
- Verification per task = `npm run build` succeeds (and dev-server visual check where noted), not unit tests — this is a presentation shell with no logic to TDD.

---

### Task 1: Scaffold Astro project

**Files:**
- Create: `package.json`, `astro.config.mjs`, `tsconfig.json`
- Create: `src/pages/index.astro` (temporary placeholder, replaced in Task 4)
- Note: `.gitignore` already exists (`node_modules/`, `dist/`, `.astro/`, `.DS_Store`)

**Interfaces:**
- Produces: a runnable Astro project (`npm run dev`, `npm run build`) at repo root.

- [ ] **Step 1: Create `package.json`**

```json
{
  "name": "neel-portfolio",
  "type": "module",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "astro": "^4.15.0"
  }
}
```

- [ ] **Step 2: Create `astro.config.mjs`**

```js
import { defineConfig } from 'astro/config';

export default defineConfig({
  // static build (default). Add integrations here later if needed.
});
```

- [ ] **Step 3: Create `tsconfig.json`**

```json
{
  "extends": "astro/tsconfigs/strict"
}
```

- [ ] **Step 4: Create a temporary `src/pages/index.astro`**

```astro
<html lang="en">
  <head><meta charset="utf-8" /><title>Portfolio</title></head>
  <body><h1>scaffold ok</h1></body>
</html>
```

- [ ] **Step 5: Install and build**

Run: `npm install && npm run build`
Expected: install completes; build prints "Complete!" and writes `dist/index.html`. No errors.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: scaffold Astro project"
```

---

### Task 2: Global styles & design tokens

**Files:**
- Create: `src/styles/global.css`

**Interfaces:**
- Produces: CSS custom properties consumed by every component:
  `--fg` (#141414), `--bg` (#ffffff), `--muted` (#8a8a8a), `--border` (#e5e5e5),
  `--space-1..6`, `--max-w` (720px), `--sidebar-w` (32%), `--bp` reference 768px.
  Also a base reset, body typography, and `a` styles.

- [ ] **Step 1: Write `src/styles/global.css`**

```css
:root {
  --fg: #141414;
  --bg: #ffffff;
  --muted: #8a8a8a;
  --border: #e5e5e5;
  --placeholder: #f0f0f0;

  --space-1: 4px;
  --space-2: 8px;
  --space-3: 16px;
  --space-4: 24px;
  --space-5: 40px;
  --space-6: 64px;

  --max-w: 720px;
  --sidebar-w: 32%;
  --sidebar-min: 320px;

  --font: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
}

*, *::before, *::after { box-sizing: border-box; }

html, body { margin: 0; padding: 0; }

body {
  font-family: var(--font);
  color: var(--fg);
  background: var(--bg);
  font-size: 15px;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}

a { color: inherit; text-decoration: none; }
a:hover { text-decoration: underline; }

img { max-width: 100%; display: block; }

h1, h2, h3, p { margin: 0; }
```

- [ ] **Step 2: Verify it builds**

Run: `npm run build`
Expected: build succeeds (file is imported once Task 3 exists; no error now).

- [ ] **Step 3: Commit**

```bash
git add src/styles/global.css
git commit -m "feat: add global styles and design tokens"
```

---

### Task 3: Sidebar component + Layout shell

**Files:**
- Create: `src/components/Sidebar.astro`
- Create: `src/layouts/Layout.astro`

**Interfaces:**
- Consumes: `src/styles/global.css` tokens.
- Produces:
  - `Sidebar.astro` — accepts prop `activePath: string` (the current route, e.g. `"/"`), renders name, bio, nav (Work `/`, Info `/info`, Contact `/contact`) with active-state, footer links.
  - `Layout.astro` — accepts props `title: string` and `activePath: string`; renders `<html>` shell, imports `global.css`, renders `<Sidebar activePath={activePath} />` and a `<slot />` for right-panel content. Implements the responsive split: ≥768px fixed left / scrolling right; <768px stacked.

- [ ] **Step 1: Write `src/components/Sidebar.astro`**

```astro
---
interface Props { activePath: string; }
const { activePath } = Astro.props;
const links = [
  { href: "/", label: "Work" },
  { href: "/info", label: "Info" },
  { href: "/contact", label: "Contact" },
];
---
<aside class="sidebar">
  <div class="sidebar-top">
    <h1 class="name">Neel Sarode</h1>
    <p class="bio">
      Product &amp; brand designer based in San Francisco. I design clear,
      considered interfaces and identities for early-stage teams. Selected work
      below.
    </p>
    <nav class="nav">
      {links.map((l) => (
        <a
          href={l.href}
          class:list={["nav-link", { active: activePath === l.href }]}
        >{l.label}</a>
      ))}
    </nav>
  </div>
  <div class="sidebar-footer">
    <a href="mailto:neel@example.com">email ↗</a>
    <a href="https://linkedin.com" target="_blank" rel="noopener">linkedin ↗</a>
  </div>
</aside>

<style>
  .sidebar {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    height: 100%;
    padding: var(--space-5) var(--space-4);
    gap: var(--space-5);
  }
  .name { font-size: 17px; font-weight: 600; letter-spacing: -0.01em; }
  .bio {
    margin-top: var(--space-3);
    max-width: 34ch;
    color: var(--fg);
  }
  .nav {
    margin-top: var(--space-5);
    display: flex;
    flex-direction: column;
    gap: var(--space-2);
  }
  .nav-link { color: var(--muted); width: fit-content; }
  .nav-link:hover { color: var(--fg); }
  .nav-link.active { color: var(--fg); text-decoration: underline; }
  .sidebar-footer {
    display: flex;
    gap: var(--space-3);
    color: var(--muted);
    font-size: 13px;
  }
  @media (max-width: 767px) {
    .sidebar {
      flex-direction: column;
      height: auto;
      padding: var(--space-4);
      gap: var(--space-4);
      border-bottom: 1px solid var(--border);
    }
    .nav { flex-direction: row; gap: var(--space-4); margin-top: var(--space-3); }
    .bio { display: none; }
  }
</style>
```

- [ ] **Step 2: Write `src/layouts/Layout.astro`**

```astro
---
import Sidebar from "../components/Sidebar.astro";
import "../styles/global.css";
interface Props { title: string; activePath: string; }
const { title, activePath } = Astro.props;
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{title}</title>
  </head>
  <body>
    <div class="shell">
      <div class="left"><Sidebar activePath={activePath} /></div>
      <main class="right"><slot /></main>
    </div>
  </body>
</html>

<style>
  .shell { min-height: 100vh; }
  .left {
    position: fixed;
    top: 0; left: 0;
    width: var(--sidebar-w);
    min-width: var(--sidebar-min);
    height: 100vh;
    border-right: 1px solid var(--border);
  }
  .right {
    margin-left: max(var(--sidebar-w), var(--sidebar-min));
    padding: var(--space-5) var(--space-5) var(--space-6);
  }
  @media (max-width: 767px) {
    .left {
      position: static;
      width: 100%;
      min-width: 0;
      height: auto;
      border-right: none;
    }
    .right { margin-left: 0; padding: var(--space-4); }
  }
</style>
```

- [ ] **Step 3: Point the temp home page at the layout (temporary)**

Replace `src/pages/index.astro` with:

```astro
---
import Layout from "../layouts/Layout.astro";
---
<Layout title="Neel Sarode — Work" activePath="/">
  <p>right panel placeholder</p>
</Layout>
```

- [ ] **Step 4: Build and visually verify**

Run: `npm run build && npm run dev`
Expected: build succeeds. In the browser at the dev URL, desktop shows a fixed left sidebar (name, bio, nav, footer) with a bordered right panel; narrowing below 768px stacks the sidebar as a top header (bio hidden, nav horizontal) with content below.

- [ ] **Step 5: Commit**

```bash
git add src/components/Sidebar.astro src/layouts/Layout.astro src/pages/index.astro
git commit -m "feat: add sidebar and split-screen layout shell"
```

---

### Task 4: Case-study content collection

**Files:**
- Create: `src/content/config.ts`
- Create: `src/content/case-studies/case-study-01.md`
- Create: `src/content/case-studies/case-study-02.md`
- Create: `src/content/case-studies/case-study-03.md`
- Create: `src/content/case-studies/case-study-04.md`

**Interfaces:**
- Produces: a `case-studies` collection. Each entry frontmatter:
  `title: string`, `category: string`, `year: number`, `tagline: string`, `order: number`.
  Entry `id`/`slug` derives from filename (e.g. `case-study-01`). Body is markdown (the full study).
  Consumed by Task 5 (home, sorted by `order`) and Task 6 (`/work/[slug]`).

- [ ] **Step 1: Write `src/content/config.ts`**

```ts
import { defineCollection, z } from "astro:content";

const caseStudies = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    category: z.string(),
    year: z.number(),
    tagline: z.string(),
    order: z.number(),
  }),
});

export const collections = { "case-studies": caseStudies };
```

- [ ] **Step 2: Write `src/content/case-studies/case-study-01.md`**

```md
---
title: "Fin — Onboarding Redesign"
category: "Product Design"
year: 2024
tagline: "Rebuilding a fintech onboarding flow to cut drop-off and set a clearer first impression."
order: 1
---

## Overview

Fin needed a first-run experience that earned trust in the first ninety seconds.
This case study walks through the research, the flows explored, and the shipped
redesign.

## Problem

The original onboarding asked for too much, too early. Placeholder body copy
describing the problem space, constraints, and goals goes here.

## Process

Placeholder content: discovery, flow mapping, prototypes, and testing rounds.

## Outcome

Placeholder content: results, metrics, and reflections.
```

- [ ] **Step 3: Write `src/content/case-studies/case-study-02.md`**

```md
---
title: "Heewon — Identity System"
category: "Brand & Identity"
year: 2023
tagline: "A bilingual identity and type system for a boutique studio spanning two markets."
order: 2
---

## Overview

Placeholder overview for the Heewon identity system case study.

## Problem

Placeholder body copy describing the brief and constraints.

## Process

Placeholder content: wordmark exploration, type pairing, and system rules.

## Outcome

Placeholder content: final identity and applications.
```

- [ ] **Step 4: Write `src/content/case-studies/case-study-03.md`**

```md
---
title: "Machinify — Dashboard UX"
category: "UI/UX"
year: 2023
tagline: "Making a dense analytics dashboard legible without hiding the data power users need."
order: 3
---

## Overview

Placeholder overview for the Machinify dashboard case study.

## Problem

Placeholder body copy describing information density challenges.

## Process

Placeholder content: audits, hierarchy work, and component design.

## Outcome

Placeholder content: shipped dashboard and adoption notes.
```

- [ ] **Step 5: Write `src/content/case-studies/case-study-04.md`**

```md
---
title: "Mise en Place — Product & Brand"
category: "Product Design"
year: 2022
tagline: "An end-to-end product and brand foundation for a kitchen-planning app."
order: 4
---

## Overview

Placeholder overview for the Mise en Place case study.

## Problem

Placeholder body copy describing the product opportunity.

## Process

Placeholder content: concepting, IA, visual language, and prototyping.

## Outcome

Placeholder content: launch and next steps.
```

- [ ] **Step 6: Build to verify the schema**

Run: `npm run build`
Expected: build succeeds; Astro syncs content types with no schema validation errors.

- [ ] **Step 7: Commit**

```bash
git add src/content
git commit -m "feat: add case-studies content collection with placeholders"
```

---

### Task 5: Home page — CaseStudyPanel + GridItem + full home layout

**Files:**
- Create: `src/components/CaseStudyPanel.astro`
- Create: `src/components/GridItem.astro`
- Modify: `src/pages/index.astro` (replace temp content)

**Interfaces:**
- Consumes: `case-studies` collection (Task 4), `Layout.astro` (Task 3).
- `CaseStudyPanel.astro` — props: `index: number`, `title: string`, `category: string`, `year: number`, `tagline: string`, `href: string`. Renders one full-width list panel with an image placeholder box; the whole panel is a link to `href`.
- `GridItem.astro` — props: `label: string`. Renders one archive tile (placeholder box + label).

- [ ] **Step 1: Write `src/components/CaseStudyPanel.astro`**

```astro
---
interface Props {
  index: number;
  title: string;
  category: string;
  year: number;
  tagline: string;
  href: string;
}
const { index, title, category, year, tagline, href } = Astro.props;
const num = String(index).padStart(2, "0");
---
<a class="panel" href={href}>
  <div class="media" aria-hidden="true"><span>{title}</span></div>
  <div class="meta">
    <div class="row">
      <span class="num">{num}</span>
      <span class="cat">{category} · {year}</span>
    </div>
    <h2 class="title">{title}</h2>
    <p class="tagline">{tagline}</p>
  </div>
</a>

<style>
  .panel {
    display: block;
    padding: var(--space-5) 0;
    border-top: 1px solid var(--border);
  }
  .panel:hover { text-decoration: none; }
  .panel:hover .title { text-decoration: underline; }
  .media {
    width: 100%;
    aspect-ratio: 16 / 9;
    background: var(--placeholder);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--muted);
    font-size: 13px;
  }
  .meta { margin-top: var(--space-3); }
  .row {
    display: flex;
    gap: var(--space-3);
    color: var(--muted);
    font-size: 13px;
    letter-spacing: 0.02em;
  }
  .num { font-variant-numeric: tabular-nums; }
  .title { margin-top: var(--space-2); font-size: 20px; font-weight: 600; }
  .tagline { margin-top: var(--space-2); color: var(--fg); max-width: 52ch; }
</style>
```

- [ ] **Step 2: Write `src/components/GridItem.astro`**

```astro
---
interface Props { label: string; }
const { label } = Astro.props;
---
<div class="item">
  <div class="media" aria-hidden="true"></div>
  <span class="label">{label}</span>
</div>

<style>
  .item { display: flex; flex-direction: column; gap: var(--space-2); }
  .media {
    width: 100%;
    aspect-ratio: 4 / 3;
    background: var(--placeholder);
  }
  .label { font-size: 13px; color: var(--muted); }
</style>
```

- [ ] **Step 3: Write `src/pages/index.astro`**

```astro
---
import { getCollection } from "astro:content";
import Layout from "../layouts/Layout.astro";
import CaseStudyPanel from "../components/CaseStudyPanel.astro";
import GridItem from "../components/GridItem.astro";

const studies = (await getCollection("case-studies")).sort(
  (a, b) => a.data.order - b.data.order
);

const archive = [
  "Poster series", "Type study", "Icon set", "Wordmark exploration",
  "Landing page", "Mobile app concept", "Editorial layout", "Motion study",
  "Packaging", "Data viz",
];
---
<Layout title="Neel Sarode — Work" activePath="/">
  <section class="case-studies">
    {studies.map((s, i) => (
      <CaseStudyPanel
        index={i + 1}
        title={s.data.title}
        category={s.data.category}
        year={s.data.year}
        tagline={s.data.tagline}
        href={`/work/${s.id}`}
      />
    ))}
  </section>

  <div class="section-label">More work</div>

  <section class="grid">
    {archive.map((label) => <GridItem label={label} />)}
  </section>
</Layout>

<style>
  .case-studies { max-width: var(--max-w); }
  .section-label {
    max-width: var(--max-w);
    margin-top: var(--space-6);
    padding-top: var(--space-3);
    border-top: 1px solid var(--border);
    color: var(--muted);
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.08em;
  }
  .grid {
    max-width: var(--max-w);
    margin-top: var(--space-4);
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-4);
  }
  @media (max-width: 767px) {
    .grid { grid-template-columns: repeat(2, 1fr); }
  }
</style>
```

- [ ] **Step 4: Build and visually verify**

Run: `npm run build && npm run dev`
Expected: home right panel shows 4 full-width case-study panels (image placeholder, num, category·year, title, tagline), then a "MORE WORK" divider label, then a 3-column grid (2-column under 768px). Each panel is a link to `/work/case-study-0N`.

- [ ] **Step 5: Commit**

```bash
git add src/components/CaseStudyPanel.astro src/components/GridItem.astro src/pages/index.astro
git commit -m "feat: build home page with case-study panels and work grid"
```

---

### Task 6: Case study detail page `/work/[slug]`

**Files:**
- Create: `src/pages/work/[slug].astro`

**Interfaces:**
- Consumes: `case-studies` collection (Task 4), `Layout.astro` (Task 3).
- Produces: a static page per case study at `/work/<id>`, rendering the markdown body with the sidebar shell intact and a back link to `/`.

- [ ] **Step 1: Write `src/pages/work/[slug].astro`**

```astro
---
import { getCollection } from "astro:content";
import Layout from "../../layouts/Layout.astro";

export async function getStaticPaths() {
  const studies = await getCollection("case-studies");
  return studies.map((entry) => ({
    params: { slug: entry.id },
    props: { entry },
  }));
}

const { entry } = Astro.props;
const { Content } = await entry.render();
---
<Layout title={`${entry.data.title} — Neel Sarode`} activePath="/">
  <article class="study">
    <a class="back" href="/">← Work</a>
    <div class="media" aria-hidden="true"></div>
    <header class="head">
      <div class="cat">{entry.data.category} · {entry.data.year}</div>
      <h1 class="title">{entry.data.title}</h1>
      <p class="tagline">{entry.data.tagline}</p>
    </header>
    <div class="body">
      <Content />
    </div>
  </article>
</Layout>

<style>
  .study { max-width: var(--max-w); }
  .back { color: var(--muted); font-size: 13px; }
  .back:hover { color: var(--fg); }
  .media {
    width: 100%;
    aspect-ratio: 16 / 9;
    background: var(--placeholder);
    margin-top: var(--space-4);
  }
  .head { margin-top: var(--space-4); }
  .cat {
    color: var(--muted);
    font-size: 13px;
    letter-spacing: 0.02em;
  }
  .title { margin-top: var(--space-2); font-size: 26px; font-weight: 600; letter-spacing: -0.01em; }
  .tagline { margin-top: var(--space-2); color: var(--fg); max-width: 52ch; }
  .body { margin-top: var(--space-5); }
  .body :global(h2) { margin-top: var(--space-5); font-size: 15px; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
  .body :global(p) { margin-top: var(--space-3); max-width: 60ch; }
</style>
```

- [ ] **Step 2: Build and visually verify**

Run: `npm run build && npm run dev`
Expected: build emits `/work/case-study-01` … `/work/case-study-04`. Visiting one (or clicking a home panel) shows the sidebar shell + full case study (back link, media placeholder, header, markdown body with styled h2/p). Back link returns to `/`.

- [ ] **Step 3: Commit**

```bash
git add src/pages/work/\[slug\].astro
git commit -m "feat: add case-study detail pages at /work/[slug]"
```

---

### Task 7: Info & Contact pages

**Files:**
- Create: `src/pages/info.astro`
- Create: `src/pages/contact.astro`

**Interfaces:**
- Consumes: `Layout.astro` (Task 3). Produces `/info` and `/contact` with placeholder content and correct active nav state.

- [ ] **Step 1: Write `src/pages/info.astro`**

```astro
---
import Layout from "../layouts/Layout.astro";
---
<Layout title="Info — Neel Sarode" activePath="/info">
  <section class="page">
    <h1>Info</h1>
    <p>
      Placeholder about copy. Neel is a product and brand designer focused on
      early-stage teams — from first identity to shipped interface. This page
      will hold a longer bio, background, and approach.
    </p>
    <p>
      Currently open to select freelance and full-time opportunities.
      Replace this with real content later.
    </p>
  </section>
</Layout>

<style>
  .page { max-width: var(--max-w); }
  .page h1 { font-size: 20px; font-weight: 600; }
  .page p { margin-top: var(--space-3); max-width: 60ch; }
</style>
```

- [ ] **Step 2: Write `src/pages/contact.astro`**

```astro
---
import Layout from "../layouts/Layout.astro";
---
<Layout title="Contact — Neel Sarode" activePath="/contact">
  <section class="page">
    <h1>Contact</h1>
    <p>Placeholder contact copy. The best way to reach me:</p>
    <ul class="links">
      <li><a href="mailto:neel@example.com">neel@example.com ↗</a></li>
      <li><a href="https://linkedin.com" target="_blank" rel="noopener">LinkedIn ↗</a></li>
    </ul>
  </section>
</Layout>

<style>
  .page { max-width: var(--max-w); }
  .page h1 { font-size: 20px; font-weight: 600; }
  .page p { margin-top: var(--space-3); max-width: 60ch; }
  .links { margin-top: var(--space-3); padding: 0; list-style: none; display: flex; flex-direction: column; gap: var(--space-2); }
</style>
```

- [ ] **Step 3: Build and visually verify**

Run: `npm run build && npm run dev`
Expected: `/info` and `/contact` render with the shell; the matching nav link shows active state on each.

- [ ] **Step 4: Commit**

```bash
git add src/pages/info.astro src/pages/contact.astro
git commit -m "feat: add Info and Contact pages"
```

---

### Task 8: Final polish & full verification

**Files:**
- Modify (as needed): any component for spacing/typography nits found during review.

**Interfaces:** none new.

- [ ] **Step 1: Full production build**

Run: `npm run build`
Expected: build succeeds; `dist/` contains `index.html`, `info/index.html`, `contact/index.html`, and `work/case-study-01..04/index.html`.

- [ ] **Step 2: Cross-check acceptance criteria in the dev server**

Run: `npm run dev`, then verify against the spec's Success Criteria:
1. Desktop: fixed left panel, independently scrolling right panel.
2. Mobile (<768px): sidebar collapses to top header, content stacks, page scrolls as one column.
3. Home: 4 full-width panels → "More work" subheading → grid of tiles.
4. Each panel links to a working `/work/[slug]` that keeps the sidebar.
5. Info & Contact exist with placeholders and active nav state.
6. Content is realistic placeholder, easy to swap.
7. Minimal black-on-white styling, intentional on both breakpoints.

Fix any spacing/typography nits inline.

- [ ] **Step 3: Commit any polish**

```bash
git add -A
git commit -m "polish: spacing and typography pass on portfolio shell"
```

---

## Self-Review

**Spec coverage:**
- Split-screen shell (fixed left / scrolling right; mobile stacks) → Task 3. ✓
- Persistent sidebar (name, bio, nav, footer, no clock) → Task 3. ✓
- 4 full-width case-study list panels → Task 5 (`CaseStudyPanel`). ✓
- Small subheading divider + grid of past designs → Task 5. ✓
- `/work/[slug]` full case study keeping the sidebar → Task 6. ✓
- Info & Contact placeholder pages → Task 7. ✓
- Astro + content collection + realistic placeholders → Tasks 1, 4. ✓
- Minimal black-on-white tokens → Task 2, used throughout. ✓

**Placeholder scan:** No "TBD/TODO/handle appropriately" — every step ships concrete code. Placeholder *copy* is intentional per spec.

**Type consistency:** `case-studies` collection name, frontmatter fields (`title/category/year/tagline/order`), and `entry.id` used consistently across Tasks 4, 5, 6. `CaseStudyPanel`/`GridItem` prop names match their call sites. `Layout` props (`title`, `activePath`) match every page. `href` pattern `/work/${s.id}` matches `getStaticPaths` `params.slug = entry.id`.
