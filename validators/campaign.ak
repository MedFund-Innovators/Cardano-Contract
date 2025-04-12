use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction}
use types/campaign.{Campaign, CampaignAction, CampaignStatus, Verification}

/// Campaign validator for MedFund
/// Helper function to check if a transaction is signed by a specific key
fn is_signed_by(tx: Transaction, vk_hash: VerificationKeyHash) -> Bool {
  list.has(tx.extra_signatories, vk_hash)
}

/// Campaign validator - Handles campaign creation, verification, withdrawal, and cancellation
validator campaign_validator {
  spend(datum: Campaign, redeemer: CampaignAction, context: ScriptContext) {
    let tx = context.transaction
    when redeemer is {
      // Create a new campaign
      CampaignAction.CreateCampaign { target, deadline } -> {
        // Ensure we have a signed transaction by the campaign owner
        let signed = is_signed_by(tx, datum.owner)
        let valid_target = target > 0
        let valid_deadline = deadline > tx.validity_range.lower_bound.limit
        let initialized =
          datum.raised_amount == 0 && datum.status == CampaignStatus.Active && datum.donors == []
        signed? && valid_target? && valid_deadline? && initialized?
      }

      // Withdraw funds by campaign owner
      CampaignAction.WithdrawFunds { campaign_id } -> {
        // Must be signed by campaign owner
        let signed = is_signed_by(tx, datum.owner)
        let verified_or_completed =
          datum.status == CampaignStatus.Verified || datum.status == CampaignStatus.Completed && datum.raised_amount >= datum.target_amount
        let correct_campaign = datum.id == campaign_id
        signed? && verified_or_completed? && correct_campaign?
      }

      // Verify a campaign by a medical professional
      CampaignAction.VerifyCampaign { campaign_id, document_hash } ->
        // Extract verifier's VK hash from signatories
        when list.head(tx.extra_signatories) is {
          Some(verifier_vkh) -> {
            // Campaign must be active and ID must match
            let active = datum.status == CampaignStatus.Active
            let correct_campaign = datum.id == campaign_id
            active? && correct_campaign?
          }
          None -> False
        }

      // Cancel a campaign (by owner or governance)
      CampaignAction.CancelCampaign { campaign_id } -> {
        // Must be signed by campaign owner and campaign must be active
        let signed = is_signed_by(tx, datum.owner)
        let active = datum.status == CampaignStatus.Active
        let correct_campaign = datum.id == campaign_id
        signed? && active? && correct_campaign?
      }
    }
  }

  else(_) {
    fail
  }
}
