import { insertWallet } from "./db/queries";
import { createWallet } from "./cardano_utils";
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
    if (process.env.BLOCKFROST_PROJECT_ID === undefined) {
      throw new Error("BLOCKFROST_PROJECT_ID is not defined");
    }
    const networks: Network[] = ["Mainnet", "Preview", "Preprod", "Custom"];
    if (!networks.includes(process.env.LUCID_NETWORK as Network)) {
      throw new Error("LUCID_NETWORK is not a valid Network type. Value is: " + process.env.LUCID_NETWORK);
    }

    this.lucid = await Lucid.new(
      new Blockfrost(
        `https://cardano-${process.env.LUCID_NETWORK!.toLowerCase()}.blockfrost.io/api/v0`,
        process.env.BLOCKFROST_PROJECT_ID
      ),
      process.env.LUCID_NETWORK as Network,
    );
  }

  private openDatabase(): void {
    if (process.env.DB_FILE_NAME === undefined) {
      throw new Error("DB_FILE_NAME is not defined");
    }

    sqlite3.verbose()
    this.db = new sqlite3.Database(process.env.DB_FILE_NAME);
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
