import { SupplyChainRunner } from "./runner.ts";

const runner = await SupplyChainRunner.init();

const wallets = runner.createWallets(5);
await runner.createUserNFTCertificate(wallets[0].address);
