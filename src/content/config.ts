import { defineCollection, z } from "astro:content";

const caseStudies = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    category: z.string(),
    year: z.number(),
    tagline: z.string(),
    order: z.number(),
    /* Optional looping preview video for the media block (public/ path). */
    video: z.string().optional(),
    videoPoster: z.string().optional(),
  }),
});

export const collections = { "case-studies": caseStudies };
