import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schemapg';

const pool = new Pool({
  connectionString: process.env.DB_URL,
  database: 'hotelica',
});

const db = drizzle(pool, { schema });

export default db;
