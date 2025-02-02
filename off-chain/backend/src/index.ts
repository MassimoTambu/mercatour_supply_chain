import { SupplyChainRunner } from "./runner.ts";

const runner = await SupplyChainRunner.init();

const wallets = runner.createWallets(5);
await runner.createUserNFTCertificates(wallets.map(w => w.address));
