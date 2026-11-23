/**
 * One-time migration + seed for localized menu names.
 *
 *   node scripts/localize_menu_names.js
 *
 * 1. Adds nullable `name_hi` / `name_gu` columns to `products` and `categories`
 *    if they don't already exist (non-destructive — existing data untouched).
 * 2. Fills them in for any item whose English name is found in
 *    src/locales/dish_names.json (case-insensitive, trimmed). Rows that already
 *    have a translation, or whose name isn't in the dictionary, are left alone
 *    (they fall back to English at runtime).
 *
 * Safe to re-run. Add more items to dish_names.json and run again anytime.
 */
require('dotenv').config();
const { pool } = require('../src/config/database');
const dict = require('../src/locales/dish_names.json');

const TABLES = ['products', 'categories'];

async function columnExists(table, column) {
  const [rows] = await pool.query(
    `SELECT COUNT(*) AS c FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?`,
    [table, column]
  );
  return rows[0].c > 0;
}

async function ensureColumns(table) {
  for (const col of ['name_hi', 'name_gu']) {
    if (!(await columnExists(table, col))) {
      await pool.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${col}\` VARCHAR(255) NULL AFTER \`name\``);
      console.log(`  + added ${table}.${col}`);
    } else {
      console.log(`  = ${table}.${col} already exists`);
    }
  }
}

function buildLookup() {
  const map = new Map();
  for (const [en, t] of Object.entries(dict)) {
    if (en.startsWith('_') || !t || typeof t !== 'object') continue;
    map.set(en.trim().toLowerCase(), t);
  }
  return map;
}

async function populate(table, lookup) {
  const [rows] = await pool.query(`SELECT id, name, name_hi, name_gu FROM \`${table}\``);
  let updated = 0;
  let matched = 0;
  for (const r of rows) {
    const key = (r.name || '').trim().toLowerCase();
    const t = lookup.get(key);
    if (!t) continue;
    matched++;
    const hi = (r.name_hi == null || r.name_hi === '') ? (t.hi || null) : r.name_hi;
    const gu = (r.name_gu == null || r.name_gu === '') ? (t.gu || null) : r.name_gu;
    if (hi !== r.name_hi || gu !== r.name_gu) {
      await pool.query(`UPDATE \`${table}\` SET name_hi = ?, name_gu = ? WHERE id = ?`, [hi, gu, r.id]);
      updated++;
    }
  }
  console.log(`  ${table}: ${rows.length} rows, ${matched} matched dictionary, ${updated} updated`);
}

(async () => {
  try {
    const lookup = buildLookup();
    console.log(`Dictionary entries: ${lookup.size}`);
    for (const table of TABLES) {
      console.log(`\n[${table}]`);
      await ensureColumns(table);
      await populate(table, lookup);
    }
    console.log('\nDone. Items not in the dictionary stay in English (safe fallback).');
  } catch (e) {
    console.error('FAILED:', e.message);
    process.exitCode = 1;
  } finally {
    try { await pool.end(); } catch (_) {}
  }
})();
