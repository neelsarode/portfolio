# Experience Timeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Experience section on the homepage where vertical scroll drives a horizontal timeline of work history, with a ruler track that reacts as entries pass.

**Architecture:** A self-contained Astro component (`ExperienceTimeline.astro`) holding data, markup, scoped styles, and its motion script. The homepage imports it and renders it after More Work. Desktop motion is a GSAP ScrollTrigger pin on the `<section>` itself plus a scrubbed x-tween on the track; per-entry choreography hangs off that tween via `containerAnimation`. Below 900px and for reduced motion, no JS runs and CSS alone stacks the entries vertically.

**Tech Stack:** Astro 4, GSAP 3 + ScrollTrigger (already dependencies), Lenis smooth scroll (already wired), plain CSS with the project's token scale.

## Global Constraints

- **Worktree:** all work happens in `/Users/neelsarode/neel-portfolio/.worktrees/v2` (branch `style/v2`). The main checkout is behind and is not served.
- **Dev server:** already running on `http://localhost:4323`. Astro serves `public/` live; no restart needed for assets.
- **Verification is real, but not a committed test suite.** The project has no test framework installed (`@playwright/test`, vitest and jest are all absent from `package.json` and `node_modules`; there is no config and there are no spec files). Verification instead uses: `npm run build`, `curl` assertions against the dev server, and a **browser automation MCP** — Chrome DevTools MCP or Playwright MCP, either works — for computed geometry and scroll behaviour. The JS snippets in each task are written for `evaluate_script` and run against a live page.
- **Do not add a test framework.** Out of scope for this plan. Committed regression tests for scroll choreography are a separate decision worth making deliberately, since assertions on pin/scrub timing are notoriously brittle.
- **Layout system (CLAUDE.md, non-negotiable):** content renders inside `.content-grid`; breakouts are only `.wide`, `.full`, `.bleed-right`, `.bleed-left`, `.band`, `.full-composed`. No custom `grid-column` values.
- **All spacing uses `--space-*`.** Scale: `--space-1: 8px` … `--space-8: 128px`. Also available: `--measure: 680px`, `--wide: 920px`, `--gutter: 24px`, `--margin: clamp(20px, 5vw, 96px)`.
- **Commit after every task.** Do not batch commits.

## Geometry reference

| Value | Token | Computes to |
|---|---|---|
| Entry column width | `--wide` | 920px |
| Gap after entry | `--space-8` | 128px |
| Pitch (divider to divider) | derived | 1048px |
| Tick interval | `--space-2` | 16px |
| Tick height | `--space-3` | 24px |
| Content inset from divider | `--space-5` | 48px |
| Tick / divider stroke | — | 2px (hairline, no token; matches Figma) |

**Known accepted detail:** 1048px pitch is not a whole multiple of the 16px tick interval (65.5), so dividers do not land exactly on a tick. At a maximum 8px offset between a 2px grey tick and a 2px full-height white divider this is imperceptible. If exact alignment is ever wanted, changing the tick interval to `--space-1` (8px) guarantees it, because every token in the system is 8-based.

## File Structure

**Create: `src/components/ExperienceTimeline.astro`**
Owns everything about the section: the `experience` data array, markup, scoped styles, and the motion script. Self-contained so `index.astro` (already ~1250 lines) does not grow another ~250.

**Modify: `src/pages/index.astro`**
Two changes only: import and render the component after the More Work section, and defensively scope the global reveal selector.

---

### Task 1: Component scaffold — data and markup

**Files:**
- Create: `src/components/ExperienceTimeline.astro`
- Modify: `src/pages/index.astro` (import + render, after the `wd-band` section which ends near line 497)

**Interfaces:**
- Consumes: nothing.
- Produces: the DOM contract every later task depends on — `.exp-band` (the `<section>`, pin target), `.exp-viewport` (clips), `.exp-head`, `.exp-track` (the translating element), `.exp-entry` (× N), `.exp-divider`, `.exp-copy`, `.exp-media`, `.exp-ruler`. The `experience` array with keys `year`, `role`, `org`, `body`, `image`, `alt`.

- [ ] **Step 1: Write the failing assertion**

The section does not exist yet. This command should find nothing:

```bash
cd /Users/neelsarode/neel-portfolio/.worktrees/v2
curl -s http://localhost:4323/ | grep -c 'class="exp-band"'
```

- [ ] **Step 2: Run it to verify it fails**

Expected output: `0`

- [ ] **Step 3: Create the component**

Create `src/components/ExperienceTimeline.astro`:

```astro
---
// Experience (Figma 2462:22611) — vertical scroll drives a horizontal timeline.
// The section pins; .exp-track translates in X beneath a fixed header. A ruler
// runs edge to edge, and each entry's divider grows to full height as it reaches
// the playhead. Motion is desktop-only: below 900px (and for reduced motion) no
// JS runs and the entries stack vertically via CSS alone.
const experience = [
  {
    year: "2018",
    role: "Lead Designer",
    org: "Bank Account Builders",
    body: "Hired as lead designer at the marketing agency Bank Account Builders. Handled delivery of all client projects including sales funnel design and development and necessary branding assets. Handled back and forth communication with clients ensuring successful project delivery.",
    image: null,
    alt: "",
  },
  {
    year: "2020",
    role: "Founder",
    org: "Conversion Designer (Freelancing)",
    body: "Begin my own personal freelancing business designing and building sales funnels and websites for clients. I've continued freelancing from 2020 till today.",
    image: null,
    alt: "",
  },
  {
    year: "2020",
    role: "Founder",
    org: "Conversion Designer (Design Program)",
    body: "Created a program teaching beginner and intermediate designers how to design and build high-end sales funnels on the platform ClickFunnels through video courses and live trainings. Sold over $500,000 of revenue of the program and taught over 500 students. Owned a Facebook group giving free instructional content with 12k+ members. Created a software called “Template Builder” using Bubble.io that allowed ClickFunnels users to generate prebuilt layout templates from a massive library of templated sections I created.",
    image: null,
    alt: "",
  },
];
---

<section class="section exp-band">
  <div class="exp-viewport">
    <div class="content-grid exp-head-grid">
      <header class="full exp-head">
        <h2 class="fw-title">
          <span class="mask"><span class="line">Experience</span></span>
        </h2>
        <span class="mask"><p class="exp-blurb">What I've been up to since 2018</p></span>
      </header>
    </div>

    <div class="exp-track">
      {experience.map((item) => (
        <article class="exp-entry">
          <span class="exp-divider" aria-hidden="true"></span>
          <div class="exp-copy">
            <span class="mask"><p class="exp-year">{item.year}</p></span>
            <span class="mask"><p class="exp-role">{item.role}</p></span>
            <span class="mask"><p class="exp-org">{item.org}</p></span>
            <span class="mask"><p class="exp-body">{item.body}</p></span>
          </div>
          <div class="exp-media">
            {item.image && (
              <img
                src={item.image}
                alt={item.alt}
                width="1028"
                height="630"
                loading="lazy"
                decoding="async"
              />
            )}
          </div>
        </article>
      ))}
      <div class="exp-ruler" aria-hidden="true"></div>
    </div>
  </div>
</section>
```

Note: `image: null` renders the flat placeholder surface the Figma shows. Adding a path later turns the box into a real image with no markup change.

- [ ] **Step 4: Render it from the homepage**

In `src/pages/index.astro`, add to the imports at the top of the frontmatter (alongside the existing `SiteNav` / `GridLines` imports):

```astro
import ExperienceTimeline from "../components/ExperienceTimeline.astro";
```

Then, immediately after the closing `</section>` of the More Work band (the `wd-band` section) and before the sections that follow, add:

```astro
    <ExperienceTimeline />
```

- [ ] **Step 5: Run the assertion to verify it passes**

```bash
curl -s http://localhost:4323/ | grep -c 'class="exp-band"'
```

Expected: `1`

Then confirm the data rendered — three entries, correct copy:

```bash
curl -s http://localhost:4323/ | grep -o 'class="exp-org"[^>]*>[^<]*' | sed 's/.*>//'
```

Expected:
```
Bank Account Builders
Conversion Designer (Freelancing)
Conversion Designer (Design Program)
```

- [ ] **Step 6: Verify the build and the grid contract**

```bash
npm run build 2>&1 | tail -3
```

Expected: `[build] Complete!` with no errors.

The header must still be a direct child of `.content-grid` for `.full` to place it. Confirm the nesting survived Astro's compile:

```bash
tr '<' '\n<' < dist/index.html | grep -A1 'class="content-grid exp-head-grid"' | head -2
```

Expected: the next element is the `<header class="full exp-head">`.

- [ ] **Step 7: Commit**

```bash
git add src/components/ExperienceTimeline.astro src/pages/index.astro
git commit -m "feat(experience): timeline section scaffold — data and markup"
```

---

### Task 2: Static styles — track geometry, ruler, dividers

**Files:**
- Modify: `src/components/ExperienceTimeline.astro` (add a `<style>` block at the end)

**Interfaces:**
- Consumes: the DOM contract from Task 1.
- Produces: a horizontally overflowing `.exp-track` whose `scrollWidth` is `entries × 1048px`, with `.exp-divider` at `scaleY(0)` awaiting Task 5, and `.exp-ruler` drawing the tick strip.

- [ ] **Step 1: Write the failing assertion**

Track width is not yet set, so it collapses to the viewport. In Chrome DevTools MCP, against `http://localhost:4323/`:

```js
() => {
  const t = document.querySelector('.exp-track');
  const n = document.querySelectorAll('.exp-entry').length;
  // N entries have N-1 gaps between them, plus the track's leading --margin.
  const margin = parseFloat(getComputedStyle(t).paddingInlineStart);
  return {
    scrollWidth: t.scrollWidth,
    expected: Math.round(n * 920 + (n - 1) * 128 + margin),
  };
}
```

- [ ] **Step 2: Run it to verify it fails**

Expected: `scrollWidth` is roughly the viewport width, well under `expected` (~3088 for three entries at a 1440 viewport, where `--margin` resolves to 72px).

- [ ] **Step 3: Add the styles**

Append to `src/components/ExperienceTimeline.astro`:

```astro
<style>
  /* Pinned viewport. Height is exactly one screen — GSAP adds the scroll
     distance via its pin-spacer, so .section's min-height must be neutralised
     or the band would be taller than the pin and the track would sit low. */
  .exp-band {
    height: 100svh;
    min-height: 0;
    justify-content: flex-start;
    overflow: hidden;
  }
  .exp-viewport {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .exp-head-grid { padding-block-start: var(--space-6); }
  .exp-head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: var(--space-4);
  }
  .exp-blurb {
    margin: 0;
    font-size: 14px;
    line-height: 1.2;
    letter-spacing: -0.01em;
    color: rgba(255, 255, 255, 0.65);
    text-align: right;
  }

  /* The translating element. position:relative so the ruler can pin to its
     bottom edge and span the whole track rather than one screen.

     width:max-content + align-self:flex-start are load-bearing: .exp-viewport
     is a flex column, so the default align-self:stretch would size the track to
     the viewport and let its entries overflow. The ruler is absolutely
     positioned with inset-inline:0, so it would then span one screen instead of
     the whole timeline. max-content makes the track's own box equal its
     content, which is also what makes track.scrollWidth meaningful. */
  .exp-track {
    position: relative;
    flex: 1;
    align-self: flex-start;
    width: max-content;
    display: flex;
    align-items: stretch;
    gap: var(--space-8);
    padding-block: var(--space-6) var(--space-3);
    padding-inline-start: var(--margin);
    will-change: transform;
  }

  .exp-entry {
    position: relative;
    flex: 0 0 var(--wide);
    width: var(--wide);
    padding-inline-start: var(--space-5);
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
  }

  /* Rests invisible — the ruler's own tick is what you see at this position.
     Task 5 grows it to full height and whitens it as it reaches the playhead. */
  .exp-divider {
    position: absolute;
    inset-block: 0;
    inset-inline-start: 0;
    width: 2px;
    background: #fff;
    transform: scaleY(0);
    transform-origin: bottom;
  }

  .exp-copy { display: flex; flex-direction: column; gap: var(--space-1); }
  .exp-year,
  .exp-role { margin: 0; color: rgba(255, 255, 255, 0.65); }
  .exp-org { margin: 0; color: #fff; }
  .exp-body {
    margin-block-start: var(--space-2);
    margin-inline: 0;
    max-width: var(--measure);
    color: rgba(255, 255, 255, 0.65);
  }

  .exp-media {
    position: relative;
    aspect-ratio: 1028 / 630;
    background: rgba(255, 255, 255, 0.05);
    overflow: hidden;
  }
  .exp-media img {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  /* Ruler spans the full track, sitting on the track's bottom edge. Ticks are
     a single repeating gradient — one element regardless of track length,
     instead of the ~525 rectangles the Figma draws. */
  .exp-ruler {
    position: absolute;
    inset-inline: 0;
    inset-block-end: 0;
    height: var(--space-3);
    background: repeating-linear-gradient(
      to right,
      rgba(255, 255, 255, 0.25) 0 2px,
      transparent 2px var(--space-2)
    );
  }
</style>
```

- [ ] **Step 4: Run the assertion to verify it passes**

Re-run the snippet from Step 1.

Expected: `scrollWidth` equals `expected` within a pixel or two. The divider-to-divider pitch is 1048px (920 + 128) for interior entries, but the total is `N × 920 + (N−1) × 128 + margin`, not `N × 1048` — the last entry has no trailing gap. Also verify no horizontal page overflow:

```js
() => ({ bodyScrollW: document.body.scrollWidth, innerW: window.innerWidth })
```

Expected: `bodyScrollW` equals `innerW` (the band clips its overflow).

- [ ] **Step 5: Verify the build**

```bash
npm run build 2>&1 | tail -3
```

Expected: `[build] Complete!`

- [ ] **Step 6: Commit**

```bash
git add src/components/ExperienceTimeline.astro
git commit -m "feat(experience): track geometry, ruler and divider styles"
```

---

### Task 3: Vertical-stack fallback

Built before the motion so the base state is the fallback and JS is purely an enhancement.

**Files:**
- Modify: `src/components/ExperienceTimeline.astro` (`<style>` block)

**Interfaces:**
- Consumes: the styles from Task 2.
- Produces: a working small-screen layout that the Task 4 `matchMedia` query will simply leave alone.

- [ ] **Step 1: Write the failing assertion**

At a 500px viewport the track is still a horizontal flex row and overflows. In DevTools, resize to 500×900 and run:

```js
() => {
  const t = document.querySelector('.exp-track');
  return { dir: getComputedStyle(t).flexDirection, overflows: t.scrollWidth > window.innerWidth };
}
```

- [ ] **Step 2: Run it to verify it fails**

Expected: `{ dir: "row", overflows: true }`

- [ ] **Step 3: Add the fallback styles**

Append inside the same `<style>` block:

```css
  /* Below 900px, and for reduced motion, no JS runs (see the matchMedia query
     in the script) — so the section must be a plain vertical stack on its own.
     The fallback is an absence of behaviour, not a branch that undoes things. */
  @media (max-width: 899px), (prefers-reduced-motion: reduce) {
    .exp-band {
      height: auto;
      min-height: 0;
      overflow: visible;
    }
    .exp-viewport { overflow: visible; }
    .exp-track {
      flex-direction: column;
      /* Undo the desktop max-content sizing — stacked entries want full width. */
      width: 100%;
      align-self: stretch;
      gap: var(--space-7);
      padding-inline: var(--margin);
      padding-block-end: var(--space-6);
      will-change: auto;
    }
    .exp-entry {
      flex: 0 0 auto;
      width: 100%;
      padding-inline-start: var(--space-4);
    }
    /* Rules read as timeline markers when stacked, so show them at rest. */
    .exp-divider { transform: scaleY(1); background: rgba(255, 255, 255, 0.25); }
    .exp-head { flex-direction: column; align-items: flex-start; gap: var(--space-2); }
    .exp-blurb { text-align: left; }
    .exp-ruler { display: none; }
  }
```

- [ ] **Step 4: Run the assertion to verify it passes**

Re-run the Step 1 snippet at 500×900.

Expected: `{ dir: "column", overflows: false }`

Then confirm all three entries are readable and stacked:

```js
() => [...document.querySelectorAll('.exp-entry')]
        .map(e => Math.round(e.getBoundingClientRect().top))
```

Expected: three increasing values (stacked vertically, not overlapping).

- [ ] **Step 5: Restore the viewport and verify desktop is unaffected**

Resize back to 1440×900 and re-run the Task 2 Step 1 assertion. Expected: `scrollWidth` ≥ 3144, `dir: "row"`.

- [ ] **Step 6: Commit**

```bash
git add src/components/ExperienceTimeline.astro
git commit -m "feat(experience): vertical-stack fallback for small screens and reduced motion"
```

---

### Task 4: Pin and horizontal scrub

**Files:**
- Modify: `src/components/ExperienceTimeline.astro` (add a `<script>` block before the `<style>` block)

**Interfaces:**
- Consumes: `.exp-band`, `.exp-track` from Task 1; the geometry from Task 2.
- Produces: the module-scope `horiz` tween that Task 5 and Task 6 attach to via `containerAnimation` and `scrollTrigger.progress`.

**Why the `<section>` is the pin target:** GSAP wraps a pinned element in a `.pin-spacer`, which replaces it as its parent's child. Pinning anything inside `.content-grid` would break `.content-grid > .full` placement, because the grid's child becomes the spacer. `.content { position: relative; z-index: 1 }` is a plain block container, so a spacer inserted there is harmless.

- [ ] **Step 1: Write the failing assertion**

Nothing pins yet. In DevTools at 1440×900:

```js
async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const band = document.querySelector('.exp-band');
  band.scrollIntoView(); await sleep(600);
  const before = document.querySelector('.exp-track').getBoundingClientRect().left;
  window.scrollBy(0, 800); await sleep(600);
  const after = document.querySelector('.exp-track').getBoundingClientRect().left;
  return { before: Math.round(before), after: Math.round(after), moved: Math.round(before - after) };
}
```

- [ ] **Step 2: Run it to verify it fails**

Expected: `moved` is 0 — the track does not translate, the page just scrolls past.

- [ ] **Step 3: Add the motion script**

Insert into `src/components/ExperienceTimeline.astro`, after the markup and before the `<style>` block:

```astro
<script>
  import { gsap } from "gsap";
  import { ScrollTrigger } from "gsap/ScrollTrigger";

  gsap.registerPlugin(ScrollTrigger);

  const band = document.querySelector<HTMLElement>(".exp-band");
  const track = document.querySelector<HTMLElement>(".exp-track");

  if (band && track) {
    // Desktop, motion-friendly only. matchMedia creates the triggers on entry
    // and reverts them on exit, so crossing the breakpoint leaves no orphaned
    // pin-spacer behind.
    const mm = gsap.matchMedia();

    mm.add("(min-width: 900px) and (prefers-reduced-motion: no-preference)", () => {
      // Function-based so invalidateOnRefresh recomputes on resize instead of
      // baking in a stale width.
      const dist = () => Math.max(0, track.scrollWidth - window.innerWidth);

      const horiz = gsap.to(track, {
        x: () => -dist(),
        ease: "none",
        scrollTrigger: {
          trigger: band,
          pin: band,
          start: "top top",
          end: () => "+=" + dist(),
          scrub: true,
          anticipatePin: 1,
          invalidateOnRefresh: true,
        },
      });

      return () => {
        horiz.scrollTrigger?.kill();
        horiz.kill();
        gsap.set(track, { clearProps: "transform" });
      };
    });
  }
</script>
```

- [ ] **Step 4: Run the assertion to verify it passes**

Re-run the Step 1 snippet.

Expected: `moved` is a positive number in the hundreds — the track translated left while the page scrolled.

- [ ] **Step 5: Verify the pin held and the grid contract survived**

```js
async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const band = document.querySelector('.exp-band');
  band.scrollIntoView(); await sleep(600);
  const top1 = band.getBoundingClientRect().top;
  window.scrollBy(0, 600); await sleep(600);
  const top2 = band.getBoundingClientRect().top;
  const head = document.querySelector('.exp-head');
  return {
    pinnedInPlace: Math.abs(top1 - top2) < 4,
    headerStillPlaced: head.getBoundingClientRect().width > 0,
    spacerParent: band.parentElement.className,
  };
}
```

Expected: `pinnedInPlace: true` (the band holds position while the page scrolls), `headerStillPlaced: true`, and `spacerParent` containing `pin-spacer`.

- [ ] **Step 6: Verify no horizontal page overflow at any scroll position**

```js
() => ({ bodyScrollW: document.body.scrollWidth, innerW: window.innerWidth })
```

Expected: equal.

- [ ] **Step 7: Verify the build**

```bash
npm run build 2>&1 | tail -3
```

Expected: `[build] Complete!`

- [ ] **Step 8: Commit**

```bash
git add src/components/ExperienceTimeline.astro
git commit -m "feat(experience): pin the section and scrub the track horizontally"
```

---

### Task 5: Per-entry choreography

**Files:**
- Modify: `src/components/ExperienceTimeline.astro` (extend the `<script>`)
- Modify: `src/pages/index.astro` (scope the global reveal selector, near line 684)

**Interfaces:**
- Consumes: `horiz` from Task 4; `.exp-entry`, `.exp-divider`, `.exp-media`, `.mask > *` from Task 1.
- Produces: no new interface — terminal behaviour.

**Two beats, per the spec:** content rises as the entry enters from the right (`left 85%`); the divider only locks to white when it reaches the playhead at viewport centre (`left 50%`). Splitting them keeps a divider white only once it is *behind* the playhead, consistent with the ruler fill in Task 6.

- [ ] **Step 1: Write the failing assertion**

Dividers never grow. In DevTools at 1440×900:

```js
async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const band = document.querySelector('.exp-band');
  band.scrollIntoView(); await sleep(600);
  window.scrollBy(0, 900); await sleep(1200);
  return [...document.querySelectorAll('.exp-divider')]
    .map(d => getComputedStyle(d).transform);
}
```

- [ ] **Step 2: Run it to verify it fails**

Expected: every entry reports a matrix with a zero y-scale (e.g. `matrix(1, 0, 0, 0, 0, 0)`) — nothing has grown.

- [ ] **Step 3: Scope the global reveal selector**

In `src/pages/index.astro`, find the reveal loop (near line 684):

```js
    gsap.utils.toArray<HTMLElement>(".section [data-reveal-group]").forEach((group) => {
```

Change the selector to exclude the Experience band:

```js
    gsap.utils.toArray<HTMLElement>(".section:not(.exp-band) [data-reveal-group]").forEach((group) => {
```

The Experience entries deliberately carry no `data-reveal-group`, so this is defensive — it stops a future edit inside the band from firing every entry at once on vertical position.

- [ ] **Step 4: Add the per-entry triggers**

Inside the `mm.add(...)` callback in `ExperienceTimeline.astro`, after the `horiz` tween and before the `return () => {...}` cleanup:

```ts
      const entries = gsap.utils.toArray<HTMLElement>(".exp-entry");

      entries.forEach((entry) => {
        const risers = entry.querySelectorAll<HTMLElement>(".mask > *");
        const media = entry.querySelector<HTMLElement>(".exp-media");
        const divider = entry.querySelector<HTMLElement>(".exp-divider");

        // Beat 1 — as the entry slides in from the right. Same riser language
        // as every other section on the page.
        if (risers.length) {
          gsap.from(risers, {
            yPercent: 110,
            duration: 0.9,
            ease: "power4.out",
            stagger: 0.09,
            scrollTrigger: {
              trigger: entry,
              containerAnimation: horiz,
              start: "left 85%",
              once: true,
            },
          });
        }

        if (media) {
          gsap.from(media, {
            opacity: 0,
            duration: 0.9,
            ease: "power2.out",
            scrollTrigger: {
              trigger: entry,
              containerAnimation: horiz,
              start: "left 85%",
              once: true,
            },
          });
        }

        // Beat 2 — the divider locks in at the playhead (viewport centre), so a
        // line is white only once it is behind the playhead, matching the ruler.
        if (divider) {
          gsap.to(divider, {
            scaleY: 1,
            duration: 0.7,
            ease: "power3.out",
            scrollTrigger: {
              trigger: entry,
              containerAnimation: horiz,
              start: "left 50%",
              toggleActions: "play none none reverse",
            },
          });
        }
      });
```

- [ ] **Step 5: Run the assertion to verify it passes**

Re-run the Step 1 snippet, then scroll further and re-read.

Expected: dividers whose entries have passed the playhead report a y-scale of 1 (e.g. `matrix(1, 0, 0, 1, 0, 0)`), while entries still to the right of centre remain at 0.

- [ ] **Step 6: Verify the risers ran and scrubbing back reverses the divider**

```js
async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const band = document.querySelector('.exp-band');
  band.scrollIntoView(); await sleep(500);
  window.scrollBy(0, 1400); await sleep(1200);
  const forward = getComputedStyle(document.querySelector('.exp-divider')).transform;
  const copyVisible = getComputedStyle(
    document.querySelector('.exp-copy .mask > *')).transform;
  window.scrollBy(0, -1400); await sleep(1200);
  const back = getComputedStyle(document.querySelector('.exp-divider')).transform;
  return { forward, back, copyVisible };
}
```

Expected: `forward` has y-scale 1, `back` has y-scale 0 (reversed), and `copyVisible` is `matrix(1, 0, 0, 1, 0, 0)` or `none` — the text settled rather than being stuck mid-rise.

- [ ] **Step 7: Verify the rest of the page still reveals**

The selector change must not have broken other sections:

```js
() => [...document.querySelectorAll('.section:not(.exp-band) [data-reveal-group]')].length
```

Expected: a non-zero count (More Work, Featured Work and Intro groups still match).

Scroll through those sections and confirm their text still rises.

- [ ] **Step 8: Verify the build**

```bash
npm run build 2>&1 | tail -3
```

Expected: `[build] Complete!`

- [ ] **Step 9: Commit**

```bash
git add src/components/ExperienceTimeline.astro src/pages/index.astro
git commit -m "feat(experience): per-entry choreography on entry and at the playhead"
```

---

### Task 6: Ruler progress fill and leading glow

**Files:**
- Modify: `src/components/ExperienceTimeline.astro` (markup: add the highlight layer; styles; script)

**Interfaces:**
- Consumes: `horiz` from Task 4, `.exp-ruler` from Task 1.
- Produces: no new interface — terminal behaviour.

**How it works without per-tick DOM:** the tick pattern is periodic, so a second identical strip in white, revealed by an animated `clip-path`, makes ticks behind the playhead read as white. A soft mask window fixed at viewport centre brightens ticks as they pass through. Both read from the same scrub progress, so they stay exact against scroll.

- [ ] **Step 1: Write the failing assertion**

There is only one ruler layer and nothing tracks progress. In DevTools:

```js
() => ({
  layers: document.querySelectorAll('.exp-ruler, .exp-ruler-fill').length,
  fillExists: !!document.querySelector('.exp-ruler-fill'),
})
```

- [ ] **Step 2: Run it to verify it fails**

Expected: `{ layers: 1, fillExists: false }`

- [ ] **Step 3: Add the highlight layer to the markup**

In `ExperienceTimeline.astro`, replace the single ruler element with two stacked layers:

```astro
      <div class="exp-ruler" aria-hidden="true">
        <div class="exp-ruler-fill"></div>
      </div>
```

- [ ] **Step 4: Add the styles**

Add to the `<style>` block, after the existing `.exp-ruler` rule:

```css
  /* White ticks in the same phase as the base strip, revealed left-to-right by
     a clip-path driven from scroll progress. --exp-fill is written by the
     script; --exp-glow is the playhead's position within the track. */
  .exp-ruler-fill {
    position: absolute;
    inset: 0;
    background: repeating-linear-gradient(
      to right,
      #fff 0 2px,
      transparent 2px var(--space-2)
    );
    clip-path: inset(0 calc(100% - var(--exp-fill, 0px)) 0 0);
  }

  /* Soft window riding the playhead. Sits above the fill so ticks brighten as
     they pass through it, then settle to the flat white of the fill behind. */
  .exp-ruler::after {
    content: "";
    position: absolute;
    inset: 0;
    background: repeating-linear-gradient(
      to right,
      #fff 0 2px,
      transparent 2px var(--space-2)
    );
    -webkit-mask-image: radial-gradient(
      circle at var(--exp-glow, 0px) 50%,
      #000 0,
      transparent var(--space-8)
    );
    mask-image: radial-gradient(
      circle at var(--exp-glow, 0px) 50%,
      #000 0,
      transparent var(--space-8)
    );
    pointer-events: none;
  }

  @media (max-width: 899px), (prefers-reduced-motion: reduce) {
    .exp-ruler-fill { display: none; }
    .exp-ruler::after { display: none; }
  }
```

- [ ] **Step 5: Drive both from scroll progress**

In the `mm.add(...)` callback, add an `onUpdate` to the `horiz` tween's `scrollTrigger`. Replace the `scrollTrigger` object from Task 4 with:

```ts
        scrollTrigger: {
          trigger: band,
          pin: band,
          start: "top top",
          end: () => "+=" + dist(),
          scrub: true,
          anticipatePin: 1,
          invalidateOnRefresh: true,
          onUpdate: (self) => {
            // The playhead is viewport centre. In track coordinates that is
            // the distance scrolled plus half a screen — which is exactly how
            // far the white fill should reach.
            const playhead = self.progress * dist() + window.innerWidth / 2;
            track.style.setProperty("--exp-fill", playhead + "px");
            track.style.setProperty("--exp-glow", playhead + "px");
          },
        },
```

Because `--exp-fill` and `--exp-glow` are set on `.exp-track`, they inherit down to both ruler layers, and both are measured in the track's own coordinate space — the same space the clip-path and mask use.

- [ ] **Step 6: Run the assertion to verify it passes**

```js
async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const band = document.querySelector('.exp-band');
  band.scrollIntoView(); await sleep(600);
  const track = document.querySelector('.exp-track');
  const at0 = track.style.getPropertyValue('--exp-fill');
  window.scrollBy(0, 1200); await sleep(800);
  const at1 = track.style.getPropertyValue('--exp-fill');
  return {
    fillExists: !!document.querySelector('.exp-ruler-fill'),
    at0, at1,
    grew: parseFloat(at1) > parseFloat(at0),
  };
}
```

Expected: `fillExists: true`, and `grew: true` — the fill advances as you scroll.

- [ ] **Step 7: Verify it visually**

Take a screenshot mid-section and confirm: ticks left of centre are white, ticks right of centre are dim, and there is a soft bright pool around centre.

- [ ] **Step 8: Verify the fallback is unaffected**

Resize to 500×900. The ruler is `display: none` there, so confirm nothing throws and the stack still renders:

```js
() => ({
  rulerHidden: getComputedStyle(document.querySelector('.exp-ruler')).display,
  entries: document.querySelectorAll('.exp-entry').length,
})
```

Expected: `{ rulerHidden: "none", entries: 3 }`

- [ ] **Step 9: Verify the build and commit**

```bash
npm run build 2>&1 | tail -3
git add src/components/ExperienceTimeline.astro
git commit -m "feat(experience): ruler progress fill and playhead glow"
```

---

### Task 7: Full-page verification

**Files:** none modified unless a regression is found.

**Interfaces:** none.

- [ ] **Step 1: Confirm first-load weight did not regress**

The featured-cover gating brought first load to 1.23MB. The Experience section adds markup but no media (entry images are `null` for now), so it must not move.

Build, serve, and measure exactly as before:

```bash
npm run build 2>&1 | tail -2
npx astro preview --port 4399 &
```

Then in DevTools against `http://localhost:4399/` at 1440×900, without scrolling:

```js
() => {
  const r = performance.getEntriesByType('resource');
  const rows = r.map(e => ({ n: e.name, kb: Math.round(e.transferSize/1024) })).filter(x => x.kb > 0);
  return { totalMB: +(rows.reduce((s,x)=>s+x.kb,0)/1024).toFixed(2) };
}
```

Expected: ≈1.23MB, unchanged.

- [ ] **Step 2: Confirm the scroll budget**

```js
() => ({ pageHeightPx: document.body.scrollHeight })
```

Record the value. With three entries the added pin distance is `trackWidth − viewportWidth` ≈ `3088 − 1440` ≈ **1650px**. At eight entries it becomes `8 × 920 + 7 × 128 + 72 − 1440` ≈ **6650px**, matching the spec's ~6,900px estimate. Note the three-entry figure so the jump is expected when entries 4–8 arrive.

- [ ] **Step 3: Full scroll-through for jank and layout breaks**

Scroll the whole page top to bottom. Confirm: the hero, Intro, Featured Work and More Work sections are unchanged; the Experience pin engages and releases cleanly; no horizontal page scrollbar appears at any point; the section after Experience begins normally.

- [ ] **Step 4: Resize behaviour**

While inside the pinned section, resize the window from 1440 to 1100 and back. Confirm the track re-measures (no gap at the end of the run, no early cut-off) — this exercises `invalidateOnRefresh`.

Then resize from 1440 down past 900 to 500 and back up. Confirm the section converts to the vertical stack and back with no orphaned pin-spacer:

```js
() => ({ spacers: document.querySelectorAll('.pin-spacer').length })
```

Expected at 500px: `0`. Expected back at 1440px: `1`.

- [ ] **Step 5: Reduced motion**

In DevTools, emulate `prefers-reduced-motion: reduce`, reload, and confirm the section renders as the vertical stack with no pin and no horizontal movement.

- [ ] **Step 6: Stop the preview server and commit any fixes**

```bash
pkill -f "astro preview --port 4399"
```

If Steps 1–5 required fixes, commit them:

```bash
git add -A
git commit -m "fix(experience): <what was corrected>"
```

---

## Notes for the implementer

- **Do not restart the dev server** on 4323 — it is already running from this worktree and picks up changes automatically.
- **`svh` units:** `100svh` is deliberate over `100vh`. On mobile the collapsing address bar changes `vh` mid-pin and makes pinned sections jump; `svh` is stable. The fallback path means this mostly matters for tablets in the 900px+ range.
- **If the pin fights Lenis:** it should not — Lenis uses native window scroll and `ScrollTrigger.update` is already wired to it in `index.astro`. If jitter appears, check that wiring before adding a `scrollerProxy`, which is not needed here.
- **Entry images are deliberately `null`.** The media box renders the flat placeholder surface the Figma shows. When real images arrive, set `image` and `alt`; the markup already handles both cases and carries `width`/`height` so nothing reflows.
