# Project guidance for Claude

## Layout system (non-negotiable)
- Every page's content renders inside `.content-grid` (src/styles/grid.css).
- Children default to the 680px reading measure. NEVER set width/max-width
  on prose elements — the grid handles it.
- Breakouts use ONLY: .wide, .full, .bleed-right, .bleed-left, .band,
  .full-composed. No custom grid-column values without asking first.
- .full-composed is a full-width 12-column grid (gap: var(--gutter)) for
  hero/homepage compositions. Children are placed with grid-column spans
  (e.g. `grid-column: 10 / 13`). Long-form prose NEVER goes in
  .full-composed — prose always lives in the default content zone (680px).
- The 680px measure is the READING width, not the page width. Homepage
  sections compose on the 12-column macro grid; case study body text uses
  the measure.
- ALL spacing uses --space-* variables. No arbitrary px/rem values, no
  one-off margins. If a needed value doesn't exist on the scale, ask.
- Full-width backgrounds with aligned content: use .band (subgrid), never
  a nested max-width container.
- Section-level vertical spacing: margin-block-start with --space-6/7/8.
