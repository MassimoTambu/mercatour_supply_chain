import { ProductMetadata } from "./product_metadata.ts";
import { SupplyChainWallet } from "./supply_chain_wallet.ts";

export interface ProductAction {
  wallet: SupplyChainWallet;
  product: ProductMetadata;
  // The quantityn should be null only for burn_all action
  quantity?: number;
}
