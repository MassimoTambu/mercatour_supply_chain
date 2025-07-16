use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{from_script}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use types.{Action, Burn, BurnAll, CIP68Datum, Mint, ReMint}
use utils

// Look at CIP 67 for label definitions
// label 222: 000de140 | MER_TOKEN 4d45525f544f4b454e
pub const ft_asset_name: AssetName = #"000de1404d45525f544f4b454e"

// label 100: 000643b0 | MER_TOKEN 4d45525f544f4b454e
pub const rnft_asset_name: AssetName = #"000643b04d45525f544f4b454e"

validator register_products {
  // TODO Manage multiple operations, like:
  // - create more than one minting
  // - Concatenate register with transfer of ownership
  // TODO what to do in case of huge inputs? ("went over budget" err)
  mint(redeemer: Action, policy_id: PolicyId, self: Transaction) {
    trace @"len": list.length(self.inputs)

    when redeemer is {
      Mint -> mint_action(policy_id, self)
      ReMint -> remint_action(policy_id, self)
      Burn -> burn_action(policy_id, self)
      BurnAll -> burn_all_action(policy_id, self)
    }
  }

  spend(
    datum: Option<CIP68Datum>,
    redeemer: Action,
    _: OutputReference,
    self: Transaction,
  ) {
    trace @"Spend action"
    trace @"Check datum"
    expect Some(datum) = datum
    expect utils.check_metadata(datum.metadata)
    expect utils.check_extra_metadata(self, datum.extra)

    when redeemer is {
      ReMint | BurnAll -> True
      _ -> False
    }
  }

  else(_) {
    fail
  }
}

pub fn mint_action(policy_id: PolicyId, self: Transaction) -> Bool {
  trace @"Mint action"
  expect list.length(self.inputs) == 1
  expect Some(input) = list.at(self.inputs, 0)

  let (ft_amount, rnft_amount) = get_mint_assets_amounts(self, policy_id)
  trace @"ft_amount": ft_amount
  trace @"Find ft output"
  let ft_output =
    utils.find_asset_output_by_asset_name(
      self,
      policy_id,
      ft_asset_name,
      fn(asset_amount) {
        and {
          asset_amount > 0,
          asset_amount == ft_amount,
        }
      },
    )

  trace @"Check if Sender is the receiver as well"
  expect input.output.address == ft_output.address

  trace @"Find rnft output"
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
  expect utils.check_extra_metadata(self, datum.extra)

  // Validator address must receive RNFT
  trace @"Check if RNFT receiver is the validator address"
  from_script(policy_id).payment_credential == rnft_output.address.payment_credential
}

// Find a list of assets in the tx mint that are going to be created by this same policy_id.
// Expect to find the FT and the RNFT.
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
  expect (Some(ft_amount), Some(rnft_amount)) =
    (
      pairs.get_first(mint_assets, ft_asset_name),
      pairs.get_first(mint_assets, rnft_asset_name),
    )

  (ft_amount, rnft_amount)
}

pub fn remint_action(policy_id: PolicyId, self: Transaction) -> Bool {
  trace @"ReMint action"
  expect list.length(self.inputs) == 2

  let ft_amount = get_remint_assets_amounts(self, policy_id)
  trace @"ft_amount": ft_amount
  trace @"Find ft output"
  let ft_output =
    utils.find_asset_output_by_asset_name(
      self,
      policy_id,
      ft_asset_name,
      // I don't check the amount here, because users could have stored
      // in the used UTXO the FT from a previous minting.
      fn(asset_amount) { asset_amount > 0 },
    )

  // Since we already check that we have two inputs, here we just check
  // that the Sender of the FT is the receiver and if the last 
  // input.output is the payment UTXO to send back the RNFT to the validator.
  trace @"Check if Sender is the receiver as well"
  let validator_address = from_script(policy_id)
  expect
    list.any(
      self.inputs,
      fn(input) { input.output.address == validator_address },
    )
  expect
    list.any(
      self.inputs,
      fn(input) { input.output.address == ft_output.address },
    )

  trace @"Find rnft output"
  let rnft_output =
    utils.find_asset_output_by_asset_name(
      self,
      policy_id,
      rnft_asset_name,
      fn(asset_amount) { asset_amount == 1 },
    )
  // Validator address must receive RNFT
  trace @"Check if RNFT receiver is the validator address"
  from_script(policy_id).payment_credential == rnft_output.address.payment_credential
}

// Find a the FT assets in the tx mint that are going to be created by this same policy_id.
// Expect to find the FT only.
pub fn get_remint_assets_amounts(self: Transaction, policy_id: PolicyId) -> Int {
  trace @"mint": self.mint
  trace @"policy_id": policy_id
  let mint_assets =
    self.mint
      |> assets.tokens(policy_id)
      |> dict.to_pairs()

  expect list.length(mint_assets) == 1
  expect Some(ft_amount) = pairs.get_first(mint_assets, ft_asset_name)
  ft_amount
}

pub fn burn_action(policy_id: PolicyId, self: Transaction) -> Bool {
  trace @"Burning action"
  expect list.length(self.inputs) == 1
  expect list.length(self.outputs) == 1
  expect Some(input) = list.at(self.inputs, 0)
  let ft_amount = get_burn_assets_amount(self, policy_id)
  trace @"ft_amount": ft_amount
  expect ft_amount < 0

  trace @"Check if Sender is the receiver as well"
  expect Some(output) = list.at(self.outputs, 0)
  input.output.address == output.address
}

// Find a list of assets in the tx burn that are going to be created by this same policy_id.
// We expect to find the FT.
pub fn get_burn_assets_amount(self: Transaction, policy_id: PolicyId) -> Int {
  trace @"mint": self.mint
  trace @"policy_id": policy_id
  let mint_assets =
    self.mint
      |> assets.tokens(policy_id)
      |> dict.to_pairs()

  expect list.length(mint_assets) == 1
  expect Some(ft_amount) = pairs.get_first(mint_assets, ft_asset_name)

  ft_amount
}

pub fn burn_all_action(policy_id: PolicyId, self: Transaction) -> Bool {
  trace @"Burning all action"
  expect list.length(self.inputs) == 2
  expect list.length(self.outputs) == 1
  let (ft_amount, rnft_amount) = get_burn_all_assets_amounts(self, policy_id)
  trace @"ft_amount": ft_amount
  trace @"ft_amount": rnft_amount
  expect ft_amount < 0
  expect rnft_amount == -1

  expect Some(output) = list.at(self.outputs, 0)
  trace @"There must not be any FT left of this policy_id"
  let ft_amount: Option<Int> =
    output.value |> assets.tokens(policy_id) |> dict.get(ft_asset_name)
  expect ft_amount == None

  // Since we already check that we have two inputs, here we just check
  // that the Sender of the FT is the receiver and if the last 
  // input.output is UTXO from the validator containing the RNFT.
  trace @"Check if Sender is the receiver as well"
  let validator_address = from_script(policy_id)
  expect
    list.any(
      self.inputs,
      fn(input) { input.output.address == validator_address },
    )
  expect
    list.any(self.inputs, fn(input) { input.output.address == output.address })

  trace @"There must not be any RNFT left of this policy_id"
  let rnft_amount: Option<Int> =
    output.value |> assets.tokens(policy_id) |> dict.get(ft_asset_name)
  rnft_amount == None
}

// Find a list of assets in the tx mint that are going to be created by this same policy_id.
// Expect to find the FT and the RNFT.
pub fn get_burn_all_assets_amounts(
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
  expect (Some(ft_amount), Some(rnft_amount)) =
    (
      pairs.get_first(mint_assets, ft_asset_name),
      pairs.get_first(mint_assets, rnft_asset_name),
    )

  (ft_amount, rnft_amount)
}
