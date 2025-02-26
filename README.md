# Mercatour Supply Chain

## Preamble

This documentation focuses more in the technical details and interaction with the blockchain rather than the whole PoC idea (platform, users, subscriptions...).

## What is Mercatour?

Mercatour will be a web and mobile platform with the scope to give visibility to the individual resellers that sell local food products at the daily / weekly local markets. We can think about it like a TripAdvisor for local food resellers.
Users can access the platform and see in every market who are the resellers, what they are selling and where the products have been gathered and produced.

## The supply chain

In order to let the users know where the products come from, we want to introduce an on-chain supply chain. In this way we are able to connect producers to resellers and give to the user a transparent overview and history of the product.

Inside the existing platform, producers and resellers will have access to page where they can create, manage and transfer their products. Under the hoods it will be a very simplified blockchain wallet interface, where the products are the minted tokens from our validator. Token with a different policyId from ours and sent from wallets not part of our whitelist will be hidden (the whitelist is managed off-chain).

### Flow

Let's say we have a producer, a reseller and an user. Here are the following actions:
- **Register products**: the producer harvest the product and register what it gathered on-chain by minting new tokens from the validator. The details of the product are stored in the transaction metadata (product name, certificates, harvest and expiration date, unit of measurement) and the amount corresponds to the amount of tokens minted.
- **Transfer of ownership**: when the producer sells the product to the reseller, it sends to its wallet a transaction containing the tokens (metadata are repeated also here for this transaction).
- **Transform products**: the producer or reseller can combine products to make a new one (flour + eggs + ricotta cheese = pie) and inherits the history of all products. This and the transfer of ownership action can be done infinite times.
- **Sell products to the consumer**: this action will burn the tokens, and it is used to terminate the supply chain of the product because it has been sold to the customer.

The history of the products will be visible in the platform.

### Analysing the on-chain code

#### Register Products

Users can register new products by calling the mint validator handler.

### Getting Started


### Future

Use of Hydra? Babel Fees?
