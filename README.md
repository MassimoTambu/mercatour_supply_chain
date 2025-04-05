# Mercatour Supply Chain

## Preamble
This documentation focuses on the technical aspects and blockchain interactions, rather than the overall PoC concept (platform, users, subscriptions, etc.).

## What is Mercatour?
Mercatour is a web and mobile platform designed to provide visibility for individual resellers selling local food products at daily or weekly markets. Think of it as a "TripAdvisor" for local food resellers.
Users can browse the platform to discover which resellers are present at each market, what products they are offering, and where those products were sourced or produced.

## The Supply Chain
To offer greater transparency to users regarding the origins of the products, we are introducing an on-chain supply chain. This will allow us to track and link producers to resellers, providing customers with a transparent view of a product's journey.

Within the platform, both producers and resellers will have access to pages where they can create, manage, and transfer their products. Behind the scenes, this will function as a simplified blockchain wallet interface, where products are represented as minted tokens issued by our validator.
Tokens that do not match our specific **policyId** or come from wallets not part of our whitelist will be hidden. The whitelist management will occur off-chain.

### Flow

Let’s consider a simple supply chain involving a producer, a reseller, and a consumer. The system supports the following key actions:

- **Register Products**:
The producer harvests the product and registers it on-chain by minting new tokens through a validator. Each token represents a unit of the product, and is sent to the producer’s wallet. The product's details — such as name, description, certifications, harvest and expiration dates, image, and unit of measurement — are stored in the UTxO’s datum alongside a Reference NFT.

- **Transfer of Ownership**:
When the producer sells the product to a reseller, ownership is transferred using standard blockchain transactions. No locking scripts are used here, allowing for a more flexible and lightweight transfer process.

- **Transform Products**:
The producer or reseller can combine multiple products to create a new one (e.g., flour + eggs + ricotta cheese = pie). The new product inherits the full history of its ingredients. This transformation, along with ownership transfers, can occur as many times as needed throughout the supply chain.

- **Sell to Consumer**:
Once the product reaches the end customer, the tokens are burned. This marks the product as consumed and finalizes its lifecycle on-chain. Resellers can also burn tokens for specific reasons without sending the tokens to the users, like if the consumer is not present on chain or if the products are expired.

The complete product history — from creation to consumption — remains transparent and accessible on the platform, allowing users to trace the origins and transformations of any item.

#### Why I decided this approach

I've been carefully considering whether to use **locking scripts** — where the NFT is held at a script address to control its movement — or to rely solely on the **standard Cardano payment mechanism**. Each approach has its pros and cons:

- If the goal is **only to track NFT ownership history**, and there are **no special rules to enforce**, then locking scripts aren't necessary. The blockchain already provides enough transparency for tracking transfers.
However, using a **locking script** introduces **increased complexity and computation costs**, especially as more NFTs accumulate at the script address.
- With locking scripts, I could enforce rules around **burning or transferring ownership** based on the product's state. But in this project, I want to **preserve user flexibility**.

So instead of enforcing rules on-chain, I’ll let users **freely transfer ownership** — even directly to the final customer — but without the incentive of reclaiming the ADA tied to the token unless they burn it. In other words, **burning becomes their incentive to close the product lifecycle and retrieve their ADA**.

### Analysing the on-chain code

#### Register Products

Users can register new products by calling the mint validator handler.

### Getting Started


### Future

Use of Hydra? Babel Fees?
