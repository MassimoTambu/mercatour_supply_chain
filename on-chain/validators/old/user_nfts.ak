use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{Finite}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction, ValidityRange}
use old/custom_types.{UserCertificateDatum}

/// This is a timestamp value of: 1 Jan 1971 00:00:00
const one_year_timestamp = 31536000

validator user_nfts(verification_key_hashes: List<VerificationKeyHash>) {
  // - Check if minting policy condition returns true
  mint(_redeemer: Data, _policy_id: PolicyId, self: Transaction) {
    trace @"verification_key_hashes": verification_key_hashes
    trace @"self.extra_signatories": self.extra_signatories
    // Check if the transaction is signed by at least one authorized VKH
    self.extra_signatories
      |> list.any(fn(signer) { verification_key_hashes |> list.has(signer) })
  }

  /// Check if datum is created correctly and expiration timestamp is over the transaction execution time
  spend(
    datum: Option<UserCertificateDatum>,
    _redeemer: Data,
    _utxo: OutputReference,
    self: Transaction,
  ) {
    trace datum
    expect Some(datum) = datum
    let expiration: Int = datum.extra.2nd.expiration
    must_be_atleast_one_year_difference(self.validity_range, expiration)
  }

  else(_) {
    fail
  }
}

fn must_be_atleast_one_year_difference(
  range: ValidityRange,
  expiration_time: Int,
) {
  trace @"bound_type": range.upper_bound.bound_type
  trace @"expiration_time": expiration_time
  when range.upper_bound.bound_type is {
    Finite(tx_latest_time) ->
      (tx_latest_time + one_year_timestamp < expiration_time)?
    _ -> False
  }
}
