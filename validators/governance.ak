use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{InlineDatum, Input, Transaction}
use types/campaign.{Campaign}
use types/governance.{GovernanceAction, ProtocolParameters, VoteDatum}

/// Governance validator for MedFund
/// Helper function to check if a transaction is signed by a specific key
fn is_signed_by(tx: Transaction, vk_hash: VerificationKeyHash) -> Bool {
  list.has(tx.extra_signatories, vk_hash)
}

/// Helper function to find a campaign by ID
fn find_campaign(
  inputs: List<Input>,
  campaign_id: ByteArray,
) -> Option<Campaign> {
  list.filter_map(
    inputs,
    fn(input: Input) {
      when input.output.datum is {
        InlineDatum(inline_datum) ->
          when inline_datum is {
            Campaign { id, .. } as campaign ->
              if id == campaign_id {
                Some(campaign)
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
}

/// Governance validator - Handles voting and protocol updates
validator governance_validator {
  spend(datum: VoteDatum, redeemer: GovernanceAction, context: ScriptContext) {
    let tx = context.transaction
    when redeemer is {
      // Emergency fund release
      GovernanceAction.EmergencyFundRelease { campaign_id } ->
        // Find the campaign
        when find_campaign(tx.inputs, campaign_id) is {
          Some(campaign) -> {
            // Require a quorum of votes
            let total_votes = dict.size(datum.votes)
            let approve_votes = dict.count(datum.votes, fn(_, vote) { vote })
            // Must have enough votes for quorum and majority approves
            let has_quorum = total_votes >= datum.quorum
            let majority_approves = approve_votes > total_votes / 2
            // Voter must have signed the transaction 
            when list.head(tx.extra_signatories) is {
              Some(signer) -> {
                let signer_has_voted = dict.has_key(datum.votes, signer)
                has_quorum? && majority_approves? && signer_has_voted?
              }
              None -> False
            }
          }
          None -> False
        }
      // Update protocol parameters
      GovernanceAction.UpdateProtocol { new_parameters } -> {
        // Require a quorum of votes
        let total_votes = dict.size(datum.votes)
        let approve_votes = dict.count(datum.votes, fn(_, vote) { vote })
        // Must have enough votes for quorum and majority approves
        let has_quorum = total_votes >= datum.quorum
        let majority_approves = approve_votes > total_votes / 2
        // Ensure parameters are valid
        let valid_percentage =
          new_parameters.quorum_percentage > 0 && new_parameters.quorum_percentage <= 100
        let valid_times =
          new_parameters.min_vote_time > 0 && new_parameters.max_vote_time > new_parameters.min_vote_time
        has_quorum? && majority_approves? && valid_percentage? && valid_times?
      }
      // Vote on a campaign
      GovernanceAction.Vote { campaign_id, approve } ->
        // Find the campaign
        when find_campaign(tx.inputs, campaign_id) is {
          Some(_) ->
            // Extract voter's VK hash
            when list.head(tx.extra_signatories) is {
              Some(voter_vkh) -> {
                // Check voter hasn't voted yet or is changing vote
                let eligible_to_vote =
                  !dict.has_key(datum.votes, voter_vkh) || dict.get(
                    datum.votes,
                    voter_vkh,
                  ) != Some(approve)
                eligible_to_vote?
              }
              None -> False
            }
          None -> False
        }
    }
  }

  else(_) {
    fail
  }
}
