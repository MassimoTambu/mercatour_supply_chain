validator register_products {
  spend(
    //  datum: Option<CFdatum>,
    redeemer: CFredeemer,
    _utxo: OutputReference,
    transaction: Transaction,
  ) {
    expect Some(datum) = datum

    when redeemer.action is {
      0 ->
        cancel_campaign(
          datum,
          redeemer.campaign_id,
          transaction.extra_signatories,
        )

      1 ->
        support_campaign(
          datum,
          redeemer.campaign_id,
          transaction.extra_signatories,
        )

      2 -> claims(datum, redeemer.campaign_id, transaction.extra_signatories)
      _ -> fail
    }
  }

  else(_) {
    fail
  }
}
