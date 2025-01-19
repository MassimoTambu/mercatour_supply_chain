use cardano/script_context.{ScriptContext}
use aiken/collection/list

fn minting_policy(_redeemer: Data, ctx: ScriptContext) -> Bool {
  let txInfo = ctx.transaction

  // List of authorized verification key hashes
  let authorized_hashes = [
    #"14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6",
  ]

  // Check if the transaction is signed by at least one authorized VKH
  txInfo.extra_signatories |> list.any(fn(signer) { authorized_hashes |> list.has(signer) })
}
