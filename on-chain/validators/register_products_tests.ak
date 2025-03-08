use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{VerificationKey, VerificationKeyHash, blake2b_224}
use aiken/primitive/string
use cardano/address.{from_script}
use cardano/assets.{PolicyId, Value, from_lovelace}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use register_products
use test_kit/tx.{
  add_asset_to_tx_output, new_tx_input, new_tx_output, set_datum_of_tx_output,
  with_asset_of_tx_input,
}
use test_types.{TestAssetData}
use types.{CIP68Datum}

// Private key F540ECC5FC9444EB08F14DC6A6E22401BB360D815072969B8C15052F7D5F5D32
const verification_key: VerificationKey =
  #"bfddd82f831dbbd5ac6ccb446804ee296542e6f2e6bd1132a7de83dd22cfb066"

const vkh: ByteArray = blake2b_224(verification_key)

const policy_id: PolicyId = #"6e6f5f6e616d655f746f6b656e"

const quantity: Int = 400

const nft_asset: Value =
  assets.from_asset(policy_id, register_products.nft_asset_name, quantity)

const metadata: Pairs<Data, Data> =
  [
    Pair(
      cast_to_data(string.to_bytearray(@"name")),
      cast_to_data(string.to_bytearray(@"tomatoes")),
    ),
    Pair(
      cast_to_data(string.to_bytearray(@"description")),
      cast_to_data(string.to_bytearray(@"")),
    ),
    Pair(
      cast_to_data(string.to_bytearray(@"image")),
      cast_to_data(string.to_bytearray(@"")),
    ),
    Pair(
      cast_to_data(string.to_bytearray(@"certificates")),
      cast_to_data([string.to_bytearray(@"organic")]),
    ),
    Pair(
      cast_to_data(string.to_bytearray(@"harvest_date")),
      cast_to_data(1741199651),
    ),
    Pair(
      cast_to_data(string.to_bytearray(@"expiration_date")),
      cast_to_data(1743870851),
    ),
    Pair(
      cast_to_data(string.to_bytearray(@"measurement")),
      cast_to_data(string.to_bytearray(@"grams")),
    ),
  ]

const datum = CIP68Datum { metadata, version: 1 }

const rnft_asset: Value =
  assets.from_asset(policy_id, register_products.rnft_asset_name, 1)

const mint_value: Value = nft_asset |> assets.merge(rnft_asset)

fn cast_to_data(value: Data) -> Data {
  let data_value: Data = value
  data_value
}

fn create_transaction(
  verification_key_hash: VerificationKeyHash,
  asset_data_list: List<TestAssetData>,
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
      asset_data_list,
      fn(asset_data) {
        if contain_value(asset_data.datum) && contain_value(
          asset_data.policy_id,
        ) {
          expect Some(datum) = asset_data.datum
          expect Some(policy_id) = asset_data.policy_id
          new_tx_output(from_script(policy_id))
            |> add_asset_to_tx_output(asset_data.value)
            |> add_asset_to_tx_output(assets.from_lovelace(2_000_000))
            |> set_datum_of_tx_output(InlineDatum(datum))
        } else if contain_value(asset_data.datum) {
          expect Some(datum) = asset_data.datum
          new_tx_output(dummy_addr)
            |> add_asset_to_tx_output(asset_data.value)
            |> add_asset_to_tx_output(assets.from_lovelace(2_000_000))
            |> set_datum_of_tx_output(InlineDatum(datum))
        } else {
          new_tx_output(dummy_addr)
            |> add_asset_to_tx_output(asset_data.value)
            |> add_asset_to_tx_output(assets.from_lovelace(2_000_000))
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

fn contain_value(opt: Option<a>) -> Bool {
  when opt is {
    Some(_) -> True
    None -> False
  }
}

test mint() {
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
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
    [
      TestAssetData(nft_asset, None, None),
      TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      TestAssetData(other_asset, None, None),
    ]
  let tx = create_transaction(vkh, assets, mint_value)

  register_products.register_products.mint(Void, policy_id, tx)
}

// It will fail because of two rnft with the same amount.
// We cannot mint more than one nft-rnft couple, because we then
// don't know who belongs to what
test mint_two_assets() fail {
  let second_nft_asset =
    assets.from_asset(policy_id, register_products.nft_asset_name, 1100)
  let second_datum =
    CIP68Datum {
      metadata: list.push(
        pairs.delete_first(metadata, string.to_bytearray(@"name")),
        Pair(
          cast_to_data(string.to_bytearray(@"name")),
          cast_to_data(string.to_bytearray(@"Melons")),
        ),
      ),
      version: 1,
    }

  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
        TestAssetData(second_nft_asset, None, None),
        TestAssetData(rnft_asset, Some(second_datum), Some(policy_id)),
      ],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_different_policy_id() fail {
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
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
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(
          rnft_asset,
          Some(datum),
          Some(#"123f5f6e616d655f746f6b656e"),
        ),
      ],
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
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
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
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
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
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_empty_datum_product_name() fail {
  let datum =
    CIP68Datum {
      metadata: list.push(
        pairs.delete_first(metadata, string.to_bytearray(@"name")),
        Pair(
          cast_to_data(string.to_bytearray(@"name")),
          cast_to_data(string.to_bytearray(@"")),
        ),
      ),
      version: 1,
    }
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
      mint_value,
    )

  register_products.register_products.mint(Void, policy_id, tx)
}

test mint_empty_datum_measurement() fail {
  let datum =
    CIP68Datum {
      metadata: list.push(
        pairs.delete_first(metadata, string.to_bytearray(@"measurement")),
        Pair(
          cast_to_data(string.to_bytearray(@"measurement")),
          cast_to_data(string.to_bytearray(@"")),
        ),
      ),
      version: 1,
    }
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
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
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
      mint_value,
    )

  expect _ = register_products.get_mint_assets_amounts(tx, #"abcdef")
}

test get_mint_asset_with_different_asset_name() fail {
  // label (222): 000de140 | YOLO_TOKEN: 594f4c4f5f544f4b454e
  let nft_asset_name = #"000de140594f4c4f5f544f4b454e"
  let nft_asset: Value = assets.from_asset(policy_id, nft_asset_name, quantity)
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
      mint_value,
    )

  let (nft_amount, _) = register_products.get_mint_assets_amounts(tx, policy_id)
  expect _ =
    register_products.find_asset_output_by_asset_name(
      tx,
      policy_id,
      register_products.nft_asset_name,
      fn(asset_amount) {
        and {
          asset_amount > 0,
          asset_amount == nft_amount,
        }
      },
    )
}

test output_asset_must_contains_mint_asset_with_negative_token_value() fail {
  let nft_asset: Value =
    assets.from_asset(policy_id, register_products.nft_asset_name, -1)
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
      mint_value,
    )

  let (nft_amount, _) = register_products.get_mint_assets_amounts(tx, policy_id)
  expect _ =
    register_products.find_asset_output_by_asset_name(
      tx,
      policy_id,
      register_products.nft_asset_name,
      fn(asset_amount) {
        and {
          asset_amount > 0,
          asset_amount == nft_amount,
        }
      },
    )
}

test output_asset_must_contains_mint_asset_zero_token_value() fail {
  let nft_asset: Value =
    assets.from_asset(policy_id, register_products.nft_asset_name, 0)
  let tx =
    create_transaction(
      vkh,
      [
        TestAssetData(nft_asset, None, None),
        TestAssetData(rnft_asset, Some(datum), Some(policy_id)),
      ],
      mint_value,
    )

  let (nft_amount, _) = register_products.get_mint_assets_amounts(tx, policy_id)
  expect _ =
    register_products.find_asset_output_by_asset_name(
      tx,
      policy_id,
      register_products.nft_asset_name,
      fn(asset_amount) {
        and {
          asset_amount > 0,
          asset_amount == nft_amount,
        }
      },
    )
}

test check_metadata_different_field() {
  and {
    // missing one field
    register_products.check_metadata(
      pairs.delete_first(metadata, string.to_bytearray(@"certificates")),
    ) == False,
    // One field of too much
    register_products.check_metadata(
      list.push(
        metadata,
        Pair(
          cast_to_data(string.to_bytearray(@"foo")),
          cast_to_data(string.to_bytearray(@"bar")),
        ),
      ),
    ) == False,
    // One field replaced by another one
    register_products.check_metadata(
      list.push(
        pairs.delete_first(metadata, string.to_bytearray(@"certificates")),
        Pair(
          cast_to_data(string.to_bytearray(@"foo")),
          cast_to_data(string.to_bytearray(@"bar")),
        ),
      ),
    ) == False,
    // One field removed, two fields repeated
    register_products.check_metadata(
      list.push(
        pairs.delete_first(metadata, string.to_bytearray(@"certificates")),
        Pair(
          cast_to_data(string.to_bytearray(@"description")),
          cast_to_data(string.to_bytearray(@"bar")),
        ),
      ),
    ) == False,
  }
}

test check_metadata_wrong_type() fail {
  let metadata =
    list.push(
      pairs.delete_first(metadata, string.to_bytearray(@"harvest_date")),
      Pair(
        cast_to_data(string.to_bytearray(@"harvest_date")),
        cast_to_data(string.to_bytearray(@"string value!")),
      ),
    )

  expect _ = register_products.check_metadata(metadata)
}
