import { initializeDatabase, insertUserNFTCertificate, insertWallet } from "./queries.ts";
import { SU } from "./simulator_utils.ts";
import { Lucid, LucidEvolution } from "@lucid-evolution/lucid";
import { Blockfrost } from "@lucid-evolution/provider";
import * as sqlite3 from 'sqlite3';
import { SupplyChainWallet } from "./interfaces/supply_chain_wallet.ts";
import { Address } from "@lucid-evolution/core-types";

export class SupplyChainRunner {
  private lucid: LucidEvolution = null!;
  private db: sqlite3.Database = null!;

  private constructor() { }

  public static init = async () => {
    const runner = new SupplyChainRunner();
    runner.openDatabase();
    initializeDatabase(runner.db);
    runner.closeDatabase();
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

  createWallets(number: number): SupplyChainWallet[] {
    const wallets: SupplyChainWallet[] = [];
    this.openDatabase();
    for (let i = 0; i < number; i++) {
      wallets.push(this.newWallet());
    }
    this.closeDatabase();
    return wallets;
  }

  private newWallet(): SupplyChainWallet {
    const wallet = SU.generateWallet();
    insertWallet(this.db, wallet);
    return wallet;
  }

  async createUserNFTCertificate(receiverAddress: Address): Promise<void> {
    this.openDatabase();
    const txHash = await SU.createUserNFTCertificate(this.lucid, receiverAddress);
    const expiration = SU.getEnvVar("USER_NFT_CERTIFICATE_EXPIRATION");
    insertUserNFTCertificate(this.db, txHash, receiverAddress, expiration);
    this.closeDatabase();
  }
}
