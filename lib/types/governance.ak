use aiken/collection/dict.{Dict}
use aiken/crypto.{Blake2b_224, Hash, VerificationKeyHash}

/// Governance related types for the MedFund platform
/// Protocol parameters for governance
pub type ProtocolParameters {
  quorum_percentage: Int,
  min_vote_time: Int,
  max_vote_time: Int,
}

/// Vote data
pub type VoteDatum {
  governance_action: GovernanceAction,
  votes: Dict<VerificationKeyHash, Bool>,
  quorum: Int,
}

/// Governance actions
pub type GovernanceAction {
  // Emergency fund release
  EmergencyFundRelease { campaign_id: ByteArray }
  // Update protocol parameters
  UpdateProtocol { new_parameters: ProtocolParameters }
  // Vote on a campaign
  Vote { campaign_id: ByteArray, approve: Bool }
}
