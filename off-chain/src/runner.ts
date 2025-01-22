import { insertWallet } from "./db/queries.ts";
import { createWallet } from "./cardano_utils.ts";
import { Blockfrost, Lucid, Network } from "lucid-cardano";
import * as sqlite3 from 'sqlite3';

export class SupplyChainRunner {
  private lucid: Lucid = null!;
  private db: sqlite3.Database = null!;

  private constructor() { }

  public static init = async () => {
    const runner = new SupplyChainRunner();
    await runner.getLucid();
    return runner;
  };

  private async getLucid(): Promise<void> {
    const bfProjectId = Deno.env.get("BLOCKFROST_PROJECT_ID");
    if (bfProjectId === undefined) {
      throw new Error("BLOCKFROST_PROJECT_ID is not defined");
    }
    const networks: Network[] = ["Mainnet", "Preview", "Preprod", "Custom"];
    const lucidNetwork = Deno.env.get("LUCID_NETWORK") as Network;
    if (!networks.includes(lucidNetwork)) {
      throw new Error("LUCID_NETWORK is not a valid Network type. Value is: " + lucidNetwork);
    }

    this.lucid = await Lucid.new(
      new Blockfrost(
        `https://cardano-${lucidNetwork.toLowerCase()}.blockfrost.io/api/v0`,
        bfProjectId
      ),
      lucidNetwork,
    );
  }

  private openDatabase(): void {
    const dbFileName = Deno.env.get("DB_FILE_NAME");
    if (dbFileName === undefined) {
      throw new Error("DB_FILE_NAME is not defined");
    }

    sqlite3.verbose()
    this.db = new sqlite3.Database(dbFileName);
  }

  private closeDatabase(): void {
    this.db.close((err) => {
      if (err) {
        console.error('Error closing the database connection:', err.message);
      } else {
        console.log('Database connection closed.');
      }
    });
  }

  createWallets(number: number): void {
    this.openDatabase();
    for (let i = 0; i < number; i++) {
      this.newWallet();
    }
    this.closeDatabase();
  }

  private newWallet(): void {
    const wallet = createWallet();
    insertWallet(this.db, wallet);
  }

  createCertificate(): void {
    // TODO
    this.openDatabase();

    this.closeDatabase();
  }
}
