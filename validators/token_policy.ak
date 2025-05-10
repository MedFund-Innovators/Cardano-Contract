use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/option
use aiken/primitive/bytearray
use cardano/assets
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Datum, InlineDatum, Input, Transaction}
use types/campaign.{Campaign}
use types/token.{MedTokenParams, bronze_tier}
use utils/tokens.{generate_nft_name}

/// Helper function to find a donor's donation amount in a campaign
fn find_donation_amount(
  inputs: List<Input>,
  campaign_id: ByteArray,
  donor: VerificationKeyHash,
) -> Option<Int> {
  list.filter_map(
    inputs,
    fn(input) {
      when input.output.datum is {
        InlineDatum(inline_datum) ->
          when inline_datum is {
            Campaign { id, donors, .. } as campaign ->
              // Check if this is the correct campaign
              if id == campaign_id {
                // Find the donor in this campaign's donors list with amount >= bronze_tier
                list.filter_map(
                  donors,
                  fn(donor_entry) {
                    let (donor_vkh, donated_amount) = donor_entry
                    // Return the donation amount if this is our donor and amount >= bronze_tier
                    if donor_vkh == donor && donated_amount >= bronze_tier {
                      Some(donated_amount)
                    } else {
                      None
                    }
                  },
                )
                  |> list.head
              } else {
                None
              }
            _ -> None
          }
        // Not an InlineDatum
        _ -> None
      }
    },
  )
    |> list.head
}

/// MedNFT token policy for MedFund
/// MedNFT token policy - Mints NFTs for donors based on donation amount
validator token_policy {
  mint(redeemer: MedTokenParams, context: ScriptContext) {
    let tx = context.transaction
    let MedTokenParams { campaign_id, donor, amount } = redeemer

    // Find the input UTxO for the correct campaign and extract the donor's donated amount if >= bronze_tier
    let maybe_donation_amount =
      find_donation_amount(tx.inputs, campaign_id, donor)

    // Now, check if we found a valid input and donation amount
    when maybe_donation_amount is {
      Some(donation_amount) -> {
        // Ensure amount in redeemer matches the actual donation found on-chain
        let amount_matches = amount == donation_amount
        // Make sure the donor has signed the transaction
        let donor_signed = list.has(tx.extra_signatories, donor)
        // Validate that the correct NFT is minted
        when assets.flatten(tx.mint) is {
          // Assuming policy_id is implicitly checked by the script context
          [(policy_id, token_name, token_amount)] -> {
            // Generate the expected token name based on the validated amount
            let expected_name =
              generate_nft_name(campaign_id, donor, donation_amount)
            // Use donation_amount here
            // Ensure exactly one token with the right name is minted
            let correct_token_name = token_name == expected_name
            let correct_token_amount = token_amount == 1
            // All checks must pass
            amount_matches && donor_signed && correct_token_name && correct_token_amount
          }
          _ -> False
        }
      }
      // No valid input UTxO found meeting the criteria (campaign, donor, tier)
      None -> False
    }
  }

  else(_) {
    fail
    // Fail for any redeemer action other than minting
  }
}
