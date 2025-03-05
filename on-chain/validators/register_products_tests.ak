use aiken/collection/list
use aiken/crypto.{VerificationKey, VerificationKeyHash, blake2b_224}
use aiken/primitive/string
use cardano/address
use cardano/assets.{Value, from_lovelace}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use register_products
use test_kit/tx.{
  add_asset_to_tx_output, new_tx_input, new_tx_output, set_datum_of_tx_output,
  with_asset_of_tx_input,
}
use types.{RegisterProductsDatum}

// Private key F540ECC5FC9444EB08F14DC6A6E22401BB360D815072969B8C15052F7D5F5D32
const verification_key: VerificationKey =
  #"bfddd82f831dbbd5ac6ccb446804ee296542e6f2e6bd1132a7de83dd22cfb066"

const vkh: ByteArray = blake2b_224(verification_key)

const policy_id: ByteArray = #"6e6f5f6e616d655f746f6b656e"

const quantity: Int = 12

const nft_asset: Value =
  assets.from_asset(policy_id, register_products.nft_asset_name, quantity)

const datum =
  RegisterProductsDatum {
    product_name: string.to_bytearray(@"tomatoes"),
    certificates: [string.to_bytearray(@"organic")],
    harvest_date: 1741199651,
    expiration_date: 1743870851,
    unit_of_measurement: string.to_bytearray(@"grams"),
  }

const rnft_asset: Value =
  assets.from_asset(policy_id, register_products.rnft_asset_name, 1)

const mint_value: Value = nft_asset |> assets.merge(rnft_asset)

fn create_transaction(
  verification_key_hash: VerificationKeyHash,
  assets_with_datum: List<(Value, Option<RegisterProductsDatum>)>,
  mint_value: Value,
) -> Transaction {
  let utxo_ref =
    OutputReference(
      #"0000000000000000000000000000000000000000000000000000000000000000",
      0,
    )
  let dummy_addr = address.from_verification_key(verification_key_hash)

  let outputs: List<Output> =
    list.map(
      assets_with_datum,
      fn(asset_with_datum) {
        let output =
          new_tx_output(dummy_addr)
            |> add_asset_to_tx_output(asset_with_datum.1st)
            |> add_asset_to_tx_output(assets.from_lovelace(2_000_000))
        when asset_with_datum.2nd is {
          Some(datum) -> set_datum_of_tx_output(output, InlineDatum(datum))
          None -> output
        }
      },
    )

  let input =
    new_tx_input(utxo_ref, dummy_addr)
      |> with_asset_of_tx_input(from_lovelace(2_000_000))

  Transaction {
    ..transaction.placeholder,
    inputs: [input],
    outputs: outputs,
    fee: 2_000_000,
    mint: mint_value,
  }
}

test mint() {
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_with_other_assets_in_output() {
  let other_asset: Value =
    assets.from_asset(
      #"123f5f6e616d655f746f6b656e",
      #"0014df104d45525f544f4b454e",
      99,
    )
  let assets =
    [(nft_asset, None), (rnft_asset, Some(datum)), (other_asset, None)]
  let tx = create_transaction(vkh, assets, mint_value)

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_different_policy_id() fail {
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )
  expect _ =
    register_products.register_products.mint(
      Void,
      #"123f5f6e616d655f746f6b656e",
      tx,
    )
}

test mint_different_token_policy_id() fail {
  let nft_asset =
    assets.from_asset(
      #"123f5f6e616d655f746f6b656e",
      register_products.nft_asset_name,
      quantity,
    )
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )
  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_different_token_name() fail {
  // label (222): 000de140 | YOLO_TOKEN: 594f4c4f5f544f4b454e
  let nft_asset: Value =
    assets.from_asset(policy_id, #"000de140594f4c4f5f544f4b454e", quantity)
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_negative_token_value() fail {
  let nft_asset: Value =
    assets.from_asset(policy_id, register_products.nft_asset_name, -1)
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_zero_token_value() fail {
  let nft_asset: Value =
    assets.from_asset(policy_id, register_products.nft_asset_name, 0)
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_empty_datum_product_name() fail {
  let datum = RegisterProductsDatum { ..datum, product_name: "" }
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_empty_datum_unit_of_measurement() fail {
  let datum = RegisterProductsDatum { ..datum, unit_of_measurement: "" }
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

// --------------
// TEST FUNCTIONS
// --------------
// Here we are testing the helper functions that are used in the main
// function `mint` from the `register_products` validator.

test get_mint_asset_with_wrong_policy_id() fail {
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  expect _ = register_products.get_mint_assets_amounts(tx, #"abcdef")
}

test get_mint_asset_with_different_asset_name() fail {
  // label (222): 000de140 | YOLO_TOKEN: 594f4c4f5f544f4b454e
  let asset_name = #"000de140594f4c4f5f544f4b454e"
  let nft_asset: Value = assets.from_asset(policy_id, asset_name, quantity)
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  let (nft_amount, rnft_amount) =
    register_products.get_mint_assets_amounts(tx, policy_id)
  expect _ =
    register_products.output_assets_must_contains_mint_assets(
      tx,
      policy_id,
      nft_amount,
      rnft_amount,
    )
}

test output_asset_must_contains_mint_asset_with_negative_token_value() fail {
  let nft_asset: Value =
    assets.from_asset(policy_id, register_products.nft_asset_name, -1)
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  let (nft_amount, rnft_amount) =
    register_products.get_mint_assets_amounts(tx, policy_id)
  expect _ =
    register_products.output_assets_must_contains_mint_assets(
      tx,
      policy_id,
      nft_amount,
      rnft_amount,
    )
}

test output_asset_must_contains_mint_asset_zero_token_value() fail {
  let nft_asset: Value =
    assets.from_asset(policy_id, register_products.nft_asset_name, 0)
  let tx =
    create_transaction(
      vkh,
      [(nft_asset, None), (rnft_asset, Some(datum))],
      mint_value,
    )

  let (nft_amount, rnft_amount) =
    register_products.get_mint_assets_amounts(tx, policy_id)
  expect _ =
    register_products.output_assets_must_contains_mint_assets(
      tx,
      policy_id,
      nft_amount,
      rnft_amount,
    )
}
