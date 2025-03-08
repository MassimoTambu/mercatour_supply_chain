use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{from_script}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use types.{CIP68Datum}

// Look at CIP 67 for label definitions
// label 222: 000de140 | MER_TOKEN 4d45525f544f4b454e
pub const nft_asset_name: AssetName = #"000de1404d45525f544f4b454e"

// label 100: 000643b0 | MER_TOKEN 4d45525f544f4b454e
pub const rnft_asset_name: AssetName = #"000643b04d45525f544f4b454e"

validator register_products {
  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    // TODO Manage multiple operations, like:
    // - create more than one minting
    // - Concatenate register with transfer of ownership
    trace @"inputs": self.inputs
    expect list.length(self.inputs) == 1
    // Check receiver is this validator address
    expect Some(input) = list.at(self.inputs, 0)

    let (nft_amount, rnft_amount) = get_mint_assets_amounts(self, policy_id)
    trace @"Find nft outout"
    let nft_output =
      find_asset_output_by_asset_name(
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
      find_asset_output_by_asset_name(
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
    expect check_metadata(datum.metadata)

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

pub fn find_asset_output_by_asset_name(
  self: Transaction,
  policy_id: PolicyId,
  asset_name: AssetName,
  check_asset_amount: fn(Int) -> Bool,
) -> Output {
  trace @"asset_name": asset_name
  expect [output] =
    list.filter(
      self.outputs,
      fn(x) {
        // Implicitly expect to find the asset with given name
        let option_asset_amount: Option<Int> =
          x.value |> assets.tokens(policy_id) |> dict.get(asset_name)
        trace @"option_asset_amount": if option_asset_amount == None {
          @"Found extraneous asset. SKIP"
        } else {
          @"Found asset with correct policy_id and nft_asset_name"
        }
        when option_asset_amount is {
          None -> False
          Some(asset_amount) -> {
            trace @"Check asset amount": when
              check_asset_amount(asset_amount)
            is {
              True -> @"Passed"
              _ -> @"Failed"
            }
            check_asset_amount(asset_amount)
          }
        }
      },
    )
  output
}

// TODO change by using a prepopulated list of correct metadata and remove them when you find them in the metadata object
// The scope is to prevent duplicate metadata
pub fn check_metadata(metadata: Pairs<Data, Data>) -> Bool {
  trace @"Check metadata"
  if list.length(pairs.keys(metadata)) != 7 {
    trace @"The number of metadata keys present in the datum is not valid"
    False
  } else {
    let result =
      pairs.map(
        metadata,
        fn(k, v) {
          expect key: ByteArray = k
          when key is {
            // name
            #"6e616d65" -> {
              expect value: ByteArray = v
              value != ""
            }
            // description
            #"6465736372697074696f6e" -> True
            // image
            #"696d616765" -> True
            // certificates
            #"636572746966696361746573" -> True
            // harvest_date
            #"686172766573745f64617465" -> {
              expect value: Int = v
              value > 0
            }
            // expiration_date
            #"65787069726174696f6e5f64617465" -> {
              expect value: Int = v
              value > 0
            }
            // measurement
            #"6d6561737572656d656e74" -> {
              expect value: ByteArray = v
              value != ""
            }
            _ -> False
          }
        },
      )
    trace @"Check metadata False results": pairs.find_all(result, False)
    pairs.find_first(result, False) == None
  }
}
