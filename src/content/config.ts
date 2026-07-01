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
