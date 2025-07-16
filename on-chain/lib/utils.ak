use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Output, Transaction}
use types.{ExtraDatum}

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
        trace @"option_asset_amount": option_asset_amount
        when option_asset_amount is {
          None -> False
          Some(asset_amount) -> {
            trace @"Check asset amount": when
              check_asset_amount(asset_amount)
            is {
              True -> @"is passed"
              _ -> @"is failed"
            }
            check_asset_amount(asset_amount)
          }
        }
      },
    )
  output
}

pub fn check_metadata(metadata: Pairs<Data, Data>) -> Bool {
  trace @"Check metadata"
  if list.length(pairs.keys(metadata)) != 3 {
    trace @"The number of metadata keys present in the datum is not valid"
    False
  } else {
    // name
    expect [name] = pairs.get_all(metadata, #"6e616d65")
    expect name: ByteArray = name
    // description
    expect [_] = pairs.get_all(metadata, #"6465736372697074696f6e")
    // image
    expect [_] = pairs.get_all(metadata, #"696d616765")
    name != ""
  }
}

pub fn check_extra_metadata(self: Transaction, extra: ExtraDatum) -> Bool {
  and {
    extra.harvest_date > 0,
    extra.expiration_date > 0,
    extra.measurement != "",
    list.has(self.extra_signatories, extra.owner),
  }
}
