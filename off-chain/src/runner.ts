import { insertWallet } from "./db/queries.ts";
import { SU } from "./simulator_utils.ts";
import { Blockfrost, Lucid, networkToId } from "lucid-cardano";
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
    const bfProjectId = SU.getEnvVar("BLOCKFROST_PROJECT_ID");
    this.lucid = await Lucid.new(
      new Blockfrost(
        `https://cardano-preview.blockfrost.io/api/v0`,
        bfProjectId
      ),
      'Preview',
    );
  }

  private openDatabase(): void {
    const dbFileName = SU.getEnvVar("DB_FILE_NAME");
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
    const wallet = SU.createWallet();
    insertWallet(this.db, wallet);
  }

  createCertificate(): void {
    const networkId = networkToId('Preview');
    const signerKey = SU.getEnvVar("FUND_SIGNING_KEY");

    this.lucid.newTx()
      .addNetworkId(networkId)
      .addSignerKey(signerKey)

    this.openDatabase();
    this.closeDatabase();
  }
}
