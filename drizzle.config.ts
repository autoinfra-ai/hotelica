import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: process.env.DB_URL?.startsWith('postgres') ? 'postgresql' : 'sqlite',
  schema: './src/db/schema.ts',
  out: './drizzle',
  dbCredentials: {
    url: process.env.DB_URL || './data/db.sqlite',
  },
});
