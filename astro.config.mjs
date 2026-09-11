import { defineConfig } from 'astro/config';

export default defineConfig({
  // static build (default). Add integrations here later if needed.
  // Canonical origin — used to absolutize og:image and og:url. Must match the
  // host Vercel redirects to (apex → www), or social crawlers see a mismatch.
  site: 'https://www.neelsarode.com',
});
