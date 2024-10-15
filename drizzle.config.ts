import { defineConfig } from 'drizzle-kit';
import * as dotenv from 'dotenv';

// export default defineConfig({
//   dialect: 'sqlite',
//   schema: './src/db/schema.ts',
//   out: './drizzle',
//   dbCredentials: {
//     url: process.env.DB_URL || './data/db.sqlite',
//   },
// });

dotenv.config({ path: 'ui/.env' });

export default defineConfig({
  schema: './src/db/schemapg.ts',
  out: './drizzle',
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DB_URL || '',
  },
});