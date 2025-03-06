use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{blake2b_224, verify_ed25519_signature}
use cardano/address.{from_verification_key}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Output, Transaction}
use types.{RegisterProductsRedeemer}

// Look at CIP 67 for label definitions
// label 333: 0014df10 | MER_TOKEN 4d45525f544f4b454e
pub const asset_name: ByteArray = #"0014df104d45525f544f4b454e"

validator register_products {
  mint(
    redeemer: RegisterProductsRedeemer,
    policy_id: PolicyId,
    self: Transaction,
  ) {
    // TODO Manage multiple operations, like:
    // - create more than one minting
    // - Concatenate register with transfer of ownership
    trace @"inputs": self.inputs
    expect list.length(self.inputs) == 1
    // Check receiver is this validator address
    expect Some(input) = list.at(self.inputs, 0)

    let output =
      get_mint_asset(self, policy_id)
        |> output_asset_must_contains_mint_asset(self, policy_id, _)

    expect_signature(redeemer)

    // Sender is the receiver as well
    expect input.output.address == output.address
    // Verify if redeemer's public key equals to sender's public key
    let redeemer_address =
      redeemer.verification_key |> blake2b_224() |> from_verification_key()
    trace @"input.output.address": input.output.address
    trace @"redeemer address": redeemer_address
    input.output.address.payment_credential == redeemer_address.payment_credential
  }

  else(_) {
    fail
  }
}

pub fn expect_signature(redeemer: RegisterProductsRedeemer) -> Void {
  trace @"redeemer": redeemer.verification_key, redeemer.message, redeemer.signature
  expect
    verify_ed25519_signature(
      redeemer.verification_key,
      redeemer.message,
      redeemer.signature,
    )
}

// Find a output where its value corresponds to the mint value
pub fn get_mint_asset(
  self: Transaction,
  policy_id: PolicyId,
) -> (AssetName, Int) {
  trace @"mint": self.mint
  trace @"policy_id": policy_id
  expect [Pair(mint_asset_name, mint_amount)] =
    self.mint
      |> assets.tokens(policy_id)
      |> dict.to_pairs()
  (mint_asset_name, mint_amount)
}

// Find a output where:
// - asset name is the same as the mint asset name and the one defined in the validator
// - asset amount is the same as the mint amount
// - asset amount is greater than 0
pub fn output_asset_must_contains_mint_asset(
  self: Transaction,
  policy_id: PolicyId,
  mint_asset: (AssetName, Int),
) -> Output {
  trace @"outputs": self.outputs
  trace @"asset_name": asset_name
  trace @"mint_asset_name": mint_asset.1st
  trace @"mint_amount": mint_asset.2nd
  let outputs =
    list.filter(
      self.outputs,
      fn(x) {
        let option_asset_amount: Option<Int> =
          x.value |> assets.tokens(policy_id) |> dict.get(asset_name)
        trace @"option_asset_amount": if option_asset_amount == None {
          @"Found extraneous asset. SKIP"
        } else {
          @"Found asset with correct policy_id and asset_name"
        }
        when option_asset_amount is {
          None -> False
          Some(asset_amount) -> and {
              asset_name == mint_asset.1st,
              asset_amount > 0,
              asset_amount == mint_asset.2nd,
            }
        }
      },
    )
  expect [output] = outputs
  output
}
