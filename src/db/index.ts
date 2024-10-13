import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema';

const dbPath = process.env.DB_URL || 'data/db.sqlite';
const sqlite = new Database(dbPath);
const db = drizzle(sqlite, {
  schema: schema,
});

export default db;
