import { insertWallet } from "./queries.ts";
import { SU } from "./simulator_utils.ts";
import { Lucid, LucidEvolution } from "@lucid-evolution/lucid";
import { Blockfrost } from "@lucid-evolution/provider";
import * as sqlite3 from 'sqlite3';

export class SupplyChainRunner {
  private lucid: LucidEvolution = null!;
  private db: sqlite3.Database = null!;

  private constructor() { }

  public static init = async () => {
    const runner = new SupplyChainRunner();
    await runner.getLucid();
    return runner;
  };

  private async getLucid(): Promise<void> {
    const bfProjectId = SU.getEnvVar("BLOCKFROST_PROJECT_ID");
    this.lucid = await Lucid(
      new Blockfrost(
        `https://cardano-preview.blockfrost.io/api/v0`,
        bfProjectId
      ),
      'Preview',
    );
  }

  private openDatabase(): void {
    const dbFileName = SU.getEnvVar("DB_FILE_NAME");
    this.db = new sqlite3.Database(dbFileName);
  }

  private closeDatabase(): void {
    this.db.close();
  }

  createWallets(number: number): void {
    this.openDatabase();
    for (let i = 0; i < number; i++) {
      this.newWallet();
    }
    this.closeDatabase();
  }

  private newWallet(): void {
    const wallet = SU.generateWallet();
    insertWallet(this.db, wallet);
  }

  async createUserNFTCertificate(): Promise<void> {
    await SU.createUserNFTCertificate(this.lucid);

    // this.openDatabase();
    // this.closeDatabase();
  }
}
