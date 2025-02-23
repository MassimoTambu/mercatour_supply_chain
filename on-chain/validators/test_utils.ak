use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address
use cardano/assets.{PolicyId}
use cardano/transaction.{Input, NoDatum, Output, OutputReference, Transaction}

// First asset must be the correct one
pub fn create_transaction(
  vkh: VerificationKeyHash,
  assets: List<(PolicyId, ByteArray, Int)>,
) -> Transaction {
  let utxo_ref =
    OutputReference(
      #"0000000000000000000000000000000000000000000000000000000000000000",
      0,
    )
  let dummy_addr = address.from_verification_key(vkh)

  let outputs: List<Output> =
    list.map(
      assets,
      fn(asset) {
        let token_value = assets.from_asset(asset.1st, asset.2nd, asset.3rd)
        let tx_value =
          assets.from_lovelace(2_000_000) |> assets.merge(token_value)

        Output {
          address: dummy_addr,
          value: tx_value,
          datum: NoDatum,
          reference_script: None,
        }
      },
    )

  let input =
    Input {
      output_reference: utxo_ref,
      output: Output {
        address: dummy_addr,
        value: assets.from_lovelace(50_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }

  expect Some(first_asset) = list.at(assets, 0)
  let mint_value =
    assets.from_asset(first_asset.1st, first_asset.2nd, first_asset.3rd)

  Transaction {
    ..transaction.placeholder,
    inputs: [input],
    outputs: outputs,
    fee: 2_000_000,
    mint: mint_value,
  }
}
