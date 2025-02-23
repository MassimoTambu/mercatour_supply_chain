use aiken/crypto.{
  Signature, VerificationKey, blake2b_224, verify_ed25519_signature,
}
use register_products
use test_utils
use types.{RegisterProductsRedeemer}

// Private key F540ECC5FC9444EB08F14DC6A6E22401BB360D815072969B8C15052F7D5F5D32
const verification_key: VerificationKey =
  #"bfddd82f831dbbd5ac6ccb446804ee296542e6f2e6bd1132a7de83dd22cfb066"

const vkh: ByteArray = blake2b_224(verification_key)

const asset_name: ByteArray = register_products.asset_name

const message: ByteArray = "test"

const signature: Signature =
  #"a09834afe64b328bb6a55740c295ae9b87628b71b9e2072bcbaab81f7b91d7237cf71e1c092207abceaa257f557a5b138bbdd1a1b89935429ec7c330a1164a0a"

const policy_id: ByteArray = #"6e6f5f6e616d655f746f6b656e"

const quantity: Int = 12

const asset = (policy_id, asset_name, quantity)

test valid_signature() {
  verify_ed25519_signature(verification_key, message, signature)
}

test mint() {
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let tx = test_utils.create_transaction(vkh, [asset])

  register_products.register_products.mint(redeemer, policy_id, tx)
}

test mint_twice() {
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let tx = test_utils.create_transaction(vkh, [asset])

  register_products.register_products.mint(redeemer, policy_id, tx)
}

test mint_with_other_assets_in_output() {
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let assets =
    [asset, (#"123f5f6e616d655f746f6b656e", #"0014df104d45525f544f4b454e", 99)]
  let tx = test_utils.create_transaction(vkh, assets)

  register_products.register_products.mint(redeemer, policy_id, tx)
}

test mint_different_policy_id() fail {
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let tx = test_utils.create_transaction(vkh, [asset])

  register_products.register_products.mint(
    redeemer,
    #"123f5f6e616d655f746f6b656e",
    tx,
  )
}

test mint_different_token_name() fail {
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  // label (333): 0014df10 | YOLO_TOKEN: 594f4c4f5f544f4b454e
  let asset_name = #"0014df10594f4c4f5f544f4b454e"
  let tx =
    test_utils.create_transaction(vkh, [(policy_id, asset_name, quantity)])

  register_products.register_products.mint(redeemer, policy_id, tx)
}

test mint_negative_and_zero_token_value() fail {
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let tx1 = test_utils.create_transaction(vkh, [(policy_id, asset_name, -1)])
  let tx2 = test_utils.create_transaction(vkh, [(policy_id, asset_name, 0)])

  and {
    register_products.register_products.mint(redeemer, policy_id, tx1),
    register_products.register_products.mint(redeemer, policy_id, tx2),
  }
}

test mint_different_signature() fail {
  let signature: Signature =
    #"dbe2289e331a4a5040482a965d76545e5ccaf8e15338f475129dc429de110dcf4e521d683d9900340c6272a05f925f59208bd1bfb1a17fc0e8a4db4ea6b4db03"
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let tx = test_utils.create_transaction(vkh, [asset])

  register_products.register_products.mint(redeemer, policy_id, tx)
}

/// This test simulate the scenario when an attacker tries with
/// a replay attack to execute a transaction using the same input.
/// This is blocked by checking if the sender's public key correspond
/// to the public key inside the redeemer field.
test mint_different_verification_key() fail {
  let wrong_verification_key =
    #"41aead46286a782598104b719b6fc750c56b9dcea58090a37d38596f41eaea4f"
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)
  let vkh = blake2b_224(wrong_verification_key)
  let tx = test_utils.create_transaction(vkh, [asset])

  register_products.register_products.mint(redeemer, policy_id, tx)
}

// --------------
// TEST FUNCTIONS
// --------------
// Here we are testing the helper functions that are used in the main
// function `mint` from the `register_products` validator.

test get_mint_asset_with_wrong_policy_id() fail {
  let tx = test_utils.create_transaction(vkh, [asset])

  expect _ = register_products.get_mint_asset(tx, #"abcdef")
}

test get_mint_asset_with_different_asset_name() fail {
  // label (333): 0014df10 | YOLO_TOKEN: 594f4c4f5f544f4b454e
  let asset_name = #"0014df10594f4c4f5f544f4b454e"
  let tx =
    test_utils.create_transaction(vkh, [(policy_id, asset_name, quantity)])

  expect _ =
    register_products.get_mint_asset(tx, policy_id)
      |> register_products.output_asset_must_contains_mint_asset(tx, policy_id, _)
}

test output_asset_must_contains_mint_asset_with_negative_token_value() fail {
  let tx = test_utils.create_transaction(vkh, [(policy_id, asset_name, -1)])

  expect _ =
    register_products.get_mint_asset(tx, policy_id)
      |> register_products.output_asset_must_contains_mint_asset(tx, policy_id, _)
}

test output_asset_must_contains_mint_asset_zero_token_value() fail {
  let tx = test_utils.create_transaction(vkh, [(policy_id, asset_name, 0)])

  expect _ =
    register_products.get_mint_asset(tx, policy_id)
      |> register_products.output_asset_must_contains_mint_asset(tx, policy_id, _)
}

test expect_signature_different_signature() fail {
  let signature: Signature =
    #"dbe2289e331a4a5040482a965d76545e5ccaf8e15338f475129dc429de110dcf4e521d683d9900340c6272a05f925f59208bd1bfb1a17fc0e8a4db4ea6b4db03"
  let redeemer = RegisterProductsRedeemer(verification_key, message, signature)

  expect _ = register_products.expect_signature(redeemer)
}
