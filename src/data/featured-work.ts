// The featured case studies — the ones with a full /work/<slug> page. Shared
// by the "More work" section at the foot of every case study, which shows
// the OTHER entries in this list as a 3-up row. Covers are the same loops the homepage's
// Featured Work rows play (public/ paths). Tags are the short-form card
// version of each project's "Things I Did" (the caption fits three).
export type FeaturedWork = {
  slug: string;
  name: string;
  /** Omit while the case study page doesn't exist yet — the card renders
   *  unlinked (same rule as the homepage's Featured Work rows). */
  href?: string;
  video: string;
  poster: string;
  tags: string[];
};

export const featuredWork: FeaturedWork[] = [
  {
    slug: "tldr",
    name: "TL;DR",
    href: "/work/tldr",
    video: "/tldr-dashboard.mp4",
    poster: "/tldr-dashboard-poster.jpg",
    tags: ["Brand Identity", "Product UI/UX", "Website Design"],
  },
  {
    slug: "usdkg",
    name: "Gold Dollar",
    href: "/work/usdkg",
    video: "/gold-dollar-cover.mp4",
    poster: "/gold-dollar-poster.jpg",
    tags: ["Brand Identity", "Website Design", "Website Development"],
  },
  {
    slug: "crow-industries",
    name: "Crow Industries",
    href: "/work/crow-industries",
    video: "/crow-cover.mp4",
    poster: "/crow-poster.jpg",
    tags: ["Website Design", "AI Imagery", "AI Video"],
  },
  {
    slug: "solarshare",
    name: "SolarShare",
    // href: "/work/solarshare" — add when the page lands.
    video: "/solarshare-cover.mp4",
    poster: "/solarshare-poster.jpg",
    tags: ["Brand Identity", "Product Design", "Website Design"],
  },
];
