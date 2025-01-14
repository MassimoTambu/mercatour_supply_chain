use aiken/tx

fn minting_policy(_redeemer: Data, ctx: ScriptContext) -> Bool {
  let txInfo = ctx.transaction

  // List of authorized verification key hashes
  let authorized_hashes = Set.new([
    #<hash1>, // Replace with actual hashes
  ])

  // Check if the transaction is signed by at least one authorized VKH
  txInfo.extra_signatories.any((signer) => authorized_hashes.contains(signer))
}
