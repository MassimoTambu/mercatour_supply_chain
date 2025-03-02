import { Database } from "sqlite3";
import { SupplyChainWallet } from "./interfaces/supply_chain_wallet.ts";

export function initializeDatabase(db: Database): void {
  console.log('Initializing the database...');
  // * Signing and verification keys are stored to simplify the demonstration.
  // * They would not be stored in a real-world application.
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (payment_address TEXT PRIMARY KEY, seed_phrase TEXT, signing_key TEXT, verification_key TEXT);
    CREATE TABLE IF NOT EXISTS products (product_id TEXT PRIMARY KEY, name TEXT, description TEXT);
    CREATE TABLE IF NOT EXISTS transactions (
      transaction_hash TEXT PRIMARY KEY, 
      product_id TEXT, 
      payment_address TEXT, 
      timestamp INTEGER, 
      FOREIGN KEY(product_id) REFERENCES products(product_id), 
      FOREIGN KEY(payment_address) REFERENCES users(payment_address)
    );`
  );
}

export function insertWallet(db: Database, wallet: SupplyChainWallet): void {
  console.log('Inserting wallet into the database...');
  db.exec(
    'INSERT INTO users (payment_address, seed_phrase, signing_key, verification_key) VALUES (?, ?, ?, ?)',
    wallet.address,
    wallet.seedPhrase,
    wallet.paymentKey,
    wallet.verificationKey,
  );
}

export function insertProducts(db: Database, products: { name: string, description: string }[]): void {
  console.log('Inserting user Datum certificates into the database...');
  db.exec(
    `INSERT INTO products (name, description) VALUES (?, ?)`,
    ...products
  );
}
