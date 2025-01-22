import { RunResult, Database } from "sqlite3";
import { SupplyChainWallet } from "../interfaces/wallet.ts";

export function initializeDatabase(db: Database): void {
  // Initialize the database
  console.log('Initializing the database...');

  db.serialize(() => {
    // * Signing and verification keys are stored to simplify the demonstration.
    // * They would not be stored in a real-world application.
    db.run("CREATE TABLE users (payment_address TEXT PRIMARY KEY, signing_key TEXT, verification_key TEXT, has_certificate BOOLEAN DEFAULT 0)",
      (_: RunResult, err: Error | null) => {
        if (err) {
          console.error('Error initializing the database:', err.message);
          throw err;
        }
      }
    );
    db.run("CREATE TABLE products (product_id TEXT PRIMARY KEY, name TEXT, description TEXT)",
      (_: RunResult, err: Error | null) => {
        if (err) {
          console.error('Error initializing the database:', err.message);
          throw err;
        }
      }
    );
    db.run(`
        CREATE TABLE transactions (
            transaction_id TEXT PRIMARY KEY, 
            product_id TEXT, 
            payment_address TEXT, 
            timestamp INTEGER, 
            FOREIGN KEY(product_id) REFERENCES products(product_id), 
            FOREIGN KEY(payment_address) REFERENCES users(payment_address)
        )
    `, (_: RunResult, err: Error | null) => {
      if (err) {
        console.error('Error initializing the database:', err.message);
        throw err;
      }
    });
  });
}

export function insertWallet(db: Database, wallet: SupplyChainWallet): void {
  // Insert the wallet into the database
  console.log('Inserting wallet into the database...');

  db.serialize(() => {
    db.run(
      'INSERT INTO users (payment_address, signing_key, verification_key) VALUES (?, ?, ?)',
      wallet.paymentAddress.to_bech32(),
      wallet.signingKey.to_bech32(),
      wallet.verificationKey.to_bech32(),
      (_: RunResult, err: Error | null) => {
        if (err) {
          console.error('Error inserting wallet into the database:', err.message);
          throw err;
        } else {
          console.log('Wallet inserted successfully.');
        }
      }
    );
  }
  );
}
