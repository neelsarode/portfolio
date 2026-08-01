# Experience timeline — horizontal scroll section

**Date:** 2026-08-01
**Branch:** `style/v2`
**Figma:** [node 2462:22611](https://www.figma.com/design/tlN0T5VDfnv6rD4GDlngez/Neel-s-Resume?node-id=2462-22611)

A new homepage section, placed directly after More Work, in which vertical scroll
drives a horizontal timeline of work history. The section pins; the timeline
translates beneath a fixed header; a ruler track spans the viewport edge to edge
and reacts as the timeline moves.

## Source design

The Figma frame is 5324×1182 with 64px padding, and contains:

- A header row: "Experience" at the left, "What I've been up to since 2018" at the right
- A ruler: 2×27px ticks at 18px intervals along the bottom, running the full width
- Full-height 2×938px dividers at x = 0, 1656, 3348 — one per entry
- Three entries, each 1028px wide, content starting 40px right of its divider:
  year → role → org → body, then a 1028×630 media box 32px below the text

The Figma is a **partial mockup**. The real timeline is 6–8 entries, so all
geometry is derived from the entry array rather than hardcoded.

## Decisions

| Question | Decision |
|---|---|
| Entry count | 6–8, data-driven from an array |
| Entry media | Images (JPG/WebP), lazy-loaded |
| Below 900px | Vertical stack, no pin, no JS |
| Horizontal drive | GSAP ScrollTrigger pin + scrubbed x-tween |
| Header | Fixed; timeline slides beneath it |
| Divider lines | Grow to full height and turn white as their entry arrives |
| Small ticks | Progress fill behind the playhead + soft leading glow |

### Why ScrollTrigger over the alternatives

`containerAnimation` lets a child element carry its own trigger keyed to
**horizontal** position inside a scrubbed container. That makes per-entry
choreography declarative instead of hand-computed against scroll progress.
GSAP and ScrollTrigger are already imported by the homepage, and Lenis drives
native scroll, so pinning works without a `scrollerProxy`.

Rejected: `position: sticky` plus a manual transform (loses `containerAnimation`,
rebuilds it worse); CSS scroll-driven animations (2026 browser support still
uneven, choreography awkward to express).

## Geometry

Fitted to the existing design system rather than copying Figma's raw values.
Every spacing and sizing value resolves to an existing token; no new geometry
tokens are introduced.

| | Figma | Built | Token |
|---|---|---|---|
| Entry column | 1028px | 920px | `--wide` |
| Tick interval | 18px | 16px | `--space-2` |
| Tick height | 27px | 24px | `--space-3` |
| Gap after entry | ~588px | 128px | `--space-8` |
| Pitch (divider to divider) | 1656px | 1048px | derived |

The one exception is stroke width: ticks and dividers are 2px hairlines, matching
the Figma. That is a stroke, not spacing, and has no equivalent on the scale —
the same way `.wd-sep` already uses a 1px rule.

Gaps *within* an entry (year → role → org → body → media) use `--space-*`
normally.

The tightened pitch also shortens the pinned run: at 8 entries, Figma's 1656px
pitch would mean ~11,800px of scroll (about ten viewport heights) where 1048px
means ~6,900px (about six). One entry still fills roughly a screen, with the next
edging into view.

## Structure

```html
<section class="section exp-band">      <!-- .full: edge to edge -->
  <div class="exp-pin">                  <!-- pinned, 100svh, overflow clipped -->
    <header class="exp-head">            <!-- stays put -->
      <h2>Experience</h2>
      <p>What I've been up to since 2018</p>
    </header>
    <div class="exp-track">              <!-- the element that translates in X -->
      <article class="exp-entry">…</article>   <!-- × N -->
      <div class="exp-ruler" aria-hidden="true"></div>
    </div>
  </div>
</section>
```

Data lives in the frontmatter, same shape as `fwRows` and `dumpItems`:

```js
const experience = [
  { year: "2018", role: "Lead Designer", org: "Bank Account Builders",
    body: "Hired as lead designer at the marketing agency…",
    image: "/exp-bank-account-builders.webp", alt: "…" },
];
```

The ruler travels **with** the track, because the full-height dividers mark entry
boundaries and must stay locked to their entries.

### Ruler rendering

Figma draws ~290 individual tick rectangles; at 6–8 entries that would be ~525
nodes of pure decoration. Instead:

- **Ticks** — a single `repeating-linear-gradient` strip. Nothing about them needs
  to move independently, so they cost one element regardless of track length.
- **Dividers** — real elements, one per entry, because each animates on its own.

```css
.exp-ruler {
  height: var(--space-3);
  background: repeating-linear-gradient(to right,
    rgba(255, 255, 255, 0.25) 0 2px, transparent 2px var(--space-2));
}
```

Tick and divider colours reuse the muted-white values already in the homepage
(the `rgba(255,255,255,·)` family used by `.wd-tag`, `.wd-sep`, `.wd-blurb`);
the "arrived" state is `#fff`, matching `.wd-name` and `.wd-hi`.

### Tick reaction

Because the tick pattern is periodic, per-tick reaction needs no per-tick DOM. Two
gradient layers:

1. **Base** — dim ticks across the whole track.
2. **Highlight** — identical white ticks, revealed by an animated `clip-path` that
   tracks scroll progress. Ticks behind the playhead stay white.

A soft window fixed at the **horizontal centre of the viewport** brightens ticks
as they pass through it, with falloff to either side. Because the window is fixed
and the ticks travel, ticks light up on arrival and dim as they leave. The fill
and glow both read from the scrub progress, so they stay exact against scroll
rather than being separately animated.

This makes the playhead the section's single reference for "arrived": everything
left of viewport centre is white, everything right of it is dim. The per-entry
choreography below is split across two beats to respect that — content reveals on
entry, but the divider only locks to white when it reaches the playhead.

## Motion

```js
const dist = () => track.scrollWidth - innerWidth;
const horiz = gsap.to(track, {
  x: () => -dist(), ease: "none",
  scrollTrigger: {
    trigger: ".exp-band", pin: ".exp-pin", scrub: true,
    end: () => "+=" + dist(),
    anticipatePin: 1, invalidateOnRefresh: true,
  },
});
```

Scroll maps 1:1 to horizontal offset, so the motion feels physical. Function-based
values plus `invalidateOnRefresh` mean resize recomputes rather than baking in a
stale width. `anticipatePin` avoids the one-frame jump at pin start.

Per entry, via `containerAnimation`, on two beats:

**Beat 1 — on entry (`start: "left 85%"`), as the entry slides in from the right:**

1. **Text rises** — the site's existing `.mask > *` riser language
   (`yPercent: 110`, `stagger: .09`, `power4.out`)
2. **Media fades** — the existing `[data-fade]` treatment

**Beat 2 — at the playhead (`start: "left 50%"`), as the divider reaches centre:**

3. **Divider grows** — `scaleY` from tick-height to full, muted → `#fff`,
   `power3.out`, `transform-origin: bottom`

```js
ScrollTrigger.create({
  trigger: entry, containerAnimation: horiz, start: "left 85%",
  onEnter: () => { /* risers + media fade */ },
});
ScrollTrigger.create({
  trigger: divider, containerAnimation: horiz, start: "left 50%",
  onEnter: () => { /* grow + whiten */ },
  onLeaveBack: () => { /* shrink + dim, so scrubbing back reverses */ },
});
```

Splitting the beats keeps the divider consistent with the ruler fill: a line is
white only once it is behind the playhead, exactly like the ticks. It also reads
better — content arrives first, then the entry "locks in" as it centres.

### Global selector conflict

The homepage reveal runs on `.section [data-reveal-group]`. Experience entries
would match it and fire on **vertical** position — every entry revealing at once
as the section enters. That selector must be scoped to exclude `.exp-band` so
entries respond only to their horizontal triggers.

## Fallbacks and edge cases

**Breakpoint** — `gsap.matchMedia()` so the ScrollTrigger only exists above 900px
and is cleanly reverted when crossing, leaving no orphaned pin-spacer:

```js
const mm = gsap.matchMedia();
mm.add("(min-width: 900px) and (prefers-reduced-motion: no-preference)", () => {
  /* pin + scrub + per-entry triggers; auto-reverted on exit */
});
```

Below 900px, and for reduced-motion users, no JS runs at all — entries stack
vertically as plain cards via CSS alone. The fallback is an absence of behaviour
rather than a branch that undoes things.

**Images** — explicit `width`/`height` and `loading="lazy"`. Dimensions matter
more than usual: an unsized image reflowing inside a translated track would shift
`scrollWidth` and desync the pin distance. Verify during implementation that lazy
loading actually defers inside the clipped, transformed track rather than assuming
it.

**Scroll budget** — ~6,900px added at 8 entries, about six viewport heights,
between More Work and whatever follows.

**Accessibility** — entries are non-interactive, so the pin will not trap keyboard
focus. If entries later gain links, focusing an offscreen one would jump the
scroll and would need handling.

## Out of scope

- Entry copy and images beyond the three entries in the Figma
- Any change to Featured Work or More Work
- The `wd-*` class naming left in place after the "Work Dump" → "More Work" rename
