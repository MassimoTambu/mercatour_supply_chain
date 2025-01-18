import { Blockfrost, Lucid, Network } from "lucid-cardano";
import dotenv from "dotenv";
import * as sqlite3 from 'sqlite3';

let lucidInstance: Lucid | null = null;
let dbInstance: sqlite3.Database | null = null;

export async function getLucid(): Promise<Lucid> {
  if (lucidInstance !== null) return lucidInstance;
  
  dotenv.config();

  if (process.env.BLOCKFROST_PROJECT_ID === undefined) {
    throw new Error("BLOCKFROST_PROJECT_ID is not defined");
  }
  const networks: Network[] = ["Mainnet", "Preview", "Preprod", "Custom"];
  if (!networks.includes(process.env.LUCID_NETWORK as Network)) {
    throw new Error("LUCID_NETWORK is not a valid Network type. Value is: " + process.env.LUCID_NETWORK);
  }
  
  lucidInstance = await Lucid.new(
    new Blockfrost(
      `https://cardano-${process.env.LUCID_NETWORK!.toLowerCase()}.blockfrost.io/api/v0`,
      process.env.BLOCKFROST_PROJECT_ID
    ),
    process.env.LUCID_NETWORK as Network,
  );
  return lucidInstance;
}

export function getDatabase() {
  if (dbInstance !== null) return dbInstance;

  dotenv.config();

  if (process.env.DB_FILE_NAME === undefined) {
    throw new Error("DB_FILE_NAME is not defined");
  }

  sqlite3.verbose()
  dbInstance = new sqlite3.Database(process.env.DB_FILE_NAME);
  return dbInstance;
}
