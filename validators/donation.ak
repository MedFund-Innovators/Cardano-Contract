use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{contains}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{InlineDatum, Transaction}
use types/campaign.{Active, Campaign, CampaignStatus, Cancelled}
use types/donation.{DonationAction, DonationDatum}

/// Donation validator for MedFund
/// Helper function to check if a transaction is signed by a specific key
fn is_signed_by(tx: Transaction, vk_hash: VerificationKeyHash) -> Bool {
  list.has(tx.extra_signatories, vk_hash)
}

/// Helper function to check if deadline has passed
fn is_deadline_passed(tx: Transaction, deadline: Int) -> Bool {
  contains(tx.validity_range, deadline)
}

/// Donation validator - Handles donations and refund requests
validator donation_validator {
  spend(datum: DonationDatum, redeemer: DonationAction, context: ScriptContext) {
    let tx = context.transaction
    when redeemer is {
      // Donate to a campaign
      DonationAction.Donate { campaign_id, amount } ->
        // Find the campaign from inputs
        when
          list.filter_map(
            context.transaction.inputs,
            fn(input) {
              when input.output.datum is {
                InlineDatum(inline_datum) ->
                  when inline_datum is {
                    Campaign { id, status, deadline, .. } ->
                      if id == campaign_id {
                        Some((status, deadline))
                      } else {
                        None
                      }
                    _ -> None
                  }
                _ -> None
              }
            },
          )
            |> list.head
        is {
          Some((status, deadline)) -> {
            // Ensure campaign is active and deadline hasn't passed
            let campaign_active = status == Active
            let deadline_valid = !is_deadline_passed(tx, deadline)
            // Ensure donation amount is positive and matches datum
            let amount_valid = amount > 0 && amount == datum.amount
            // Ensure the donor has signed the transaction
            let donor_signed = is_signed_by(tx, datum.donor)
            campaign_active? && deadline_valid? && amount_valid? && donor_signed?
          }
          None -> False
        }
      // Request refund (if campaign cancelled or deadline passed without meeting target)
      DonationAction.RequestRefund { campaign_id } ->
        // Find the campaign from inputs
        when
          list.filter_map(
            context.transaction.inputs,
            fn(input) {
              when input.output.datum is {
                InlineDatum(inline_datum) ->
                  when inline_datum is {
                    Campaign {
                      id,
                      status,
                      deadline,
                      target_amount,
                      raised_amount,
                      ..
                    } ->
                      if id == campaign_id {
                        Some((status, deadline, target_amount, raised_amount))
                      } else {
                        None
                      }
                    _ -> None
                  }
                _ -> None
              }
            },
          )
            |> list.head
        is {
          Some((status, deadline, target_amount, raised_amount)) -> {
            // Verify refund conditions: campaign is canceled or deadline passed but target not met
            let cancelled = status == Cancelled
            let deadline_passed_target_not_met =
              is_deadline_passed(tx, deadline) && raised_amount < target_amount
            let refund_conditions = cancelled || deadline_passed_target_not_met
            // Ensure the donor has signed the transaction
            let donor_signed = is_signed_by(tx, datum.donor)
            refund_conditions? && donor_signed?
          }
          None -> False
        }
    }
  }

  else(_) {
    fail
  }
}
