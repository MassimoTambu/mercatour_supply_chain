use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{from_script}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use types.{CIP68Datum}
use utils

// Look at CIP 67 for label definitions
// label 222: 000de140 | MER_TOKEN 4d45525f544f4b454e
pub const nft_asset_name: AssetName = #"000de1404d45525f544f4b454e"

// label 100: 000643b0 | MER_TOKEN 4d45525f544f4b454e
pub const rnft_asset_name: AssetName = #"000643b04d45525f544f4b454e"

validator register_products {
  // TODO Manage multiple operations, like:
  // - create more than one minting
  // - Concatenate register with transfer of ownership
  // TODO what to do in case of huge inputs? ("went over budget" err)
  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    expect list.length(self.inputs) == 1
    // Check receiver is this validator address
    expect Some(input) = list.at(self.inputs, 0)

    let (nft_amount, rnft_amount) = get_mint_assets_amounts(self, policy_id)
    trace @"Find nft output"
    let nft_output =
      utils.find_asset_output_by_asset_name(
        self,
        policy_id,
        nft_asset_name,
        fn(asset_amount) {
          and {
            asset_amount > 0,
            asset_amount == nft_amount,
          }
        },
      )
    trace @"nft_output": nft_output

    trace @"Check if Sender is the receiver as well"
    // Sender is the receiver as well
    expect input.output.address == nft_output.address

    trace @"Find rnft outout"
    let rnft_output =
      utils.find_asset_output_by_asset_name(
        self,
        policy_id,
        rnft_asset_name,
        fn(asset_amount) {
          and {
            asset_amount == 1,
            asset_amount == rnft_amount,
          }
        },
      )

    trace @"Check datum"
    expect InlineDatum(datum) = rnft_output.datum
    expect datum: CIP68Datum = datum

    expect utils.check_metadata(datum.metadata)
    expect utils.check_extra_metadata(datum.extra)

    trace if from_script(policy_id).payment_credential == rnft_output.address.payment_credential {
      @"Validation Success"
    } else {
      @"Rnft receiver does not correspond to the validator address"
    }
    // Validator address must receive RNFT
    from_script(policy_id).payment_credential == rnft_output.address.payment_credential
  }

  else(_) {
    fail
  }
}

// Find a list of assets in the tx mint that are going to be created by this same policy_id.
// We expect to find the NFT and the RNFT.
pub fn get_mint_assets_amounts(
  self: Transaction,
  policy_id: PolicyId,
) -> (Int, Int) {
  trace @"mint": self.mint
  trace @"policy_id": policy_id
  let mint_assets =
    self.mint
      |> assets.tokens(policy_id)
      |> dict.to_pairs()

  expect list.length(mint_assets) == 2
  expect (Some(nft_amount), Some(rnft_amount)) =
    (
      pairs.get_first(mint_assets, nft_asset_name),
      pairs.get_first(mint_assets, rnft_asset_name),
    )

  (nft_amount, rnft_amount)
}
