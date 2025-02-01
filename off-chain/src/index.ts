import { SupplyChainRunner } from "./runner.ts";

const runner = await SupplyChainRunner.init();
await runner.createUserNFTCertificate();

// TODO initialize the database

// const utxos = await lucid.utxosAt(process.env.FUND_ADDRESS!);
// // Calculate the total ADA (lovelace)
// const totalLovelace = utxos.reduce((sum, utxo) => sum + BigInt(utxo.assets['lovelace']), BigInt(0));

// // Convert lovelace to ADA (1 ADA = 1,000,000 lovelace)
// const totalAda = Number(totalLovelace) / 1_000_000;
// console.log("Total ADA:", totalAda);
