import fs from 'fs';
import path from 'path';
import { pool } from '../config/db';

/**
 * Simple migration runner.
 * Reads SQL files from migrations/ directory in order and executes them.
 * Tracks applied migrations in a _migrations table.
 */
async function migrate() {
  const client = await pool.connect();

  try {
    // Create migrations tracking table
    await client.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    // Get already applied migrations
    const { rows: applied } = await client.query('SELECT name FROM _migrations ORDER BY id');
    const appliedSet = new Set(applied.map((r: any) => r.name));

    // Read migration files
    const migrationsDir = path.join(__dirname, 'migrations');
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      if (appliedSet.has(file)) {
        console.log(`  [skip] ${file} (already applied)`);
        continue;
      }

      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');

      console.log(`  [run]  ${file}`);
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO _migrations (name) VALUES ($1)', [file]);
        await client.query('COMMIT');
        console.log(`  [done] ${file}`);
      } catch (err) {
        await client.query('ROLLBACK');
        console.error(`  [fail] ${file}:`, err);
        throw err;
      }
    }

    console.log('\nAll migrations applied.');
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
