use aiken/collection/dict.{Dict}
use aiken/crypto.{Blake2b_224, Hash, VerificationKeyHash}

/// Campaign related types for the MedFund platform
/// Campaign status states
pub type CampaignStatus {
  Active
  Completed
  Cancelled
  Verified
}

/// Medical verification data
pub type Verification {
  // Hash of medical documents
  document_hash: ByteArray,
  // Verification key hash of the verifier (medical professional/institution)
  verifier: VerificationKeyHash,
  // Timestamp of verification
  timestamp: Int,
}

/// Campaign data structure
pub type Campaign {
  // Campaign identifier
  id: ByteArray,
  // Owner's verification key hash
  owner: VerificationKeyHash,
  // Target amount to raise
  target_amount: Int,
  // Raised amount so far
  raised_amount: Int,
  // Campaign status
  status: CampaignStatus,
  // List of donors with amounts
  donors: List<(VerificationKeyHash, Int)>,
  // Campaign deadline (POSIX time)
  deadline: Int,
  // Optional verification data (when status is Verified)
  verification: Option<Verification>,
  // Governance votes (for verified campaigns)
  votes: Dict<VerificationKeyHash, Bool>,
}

/// Campaign actions
pub type CampaignAction {
  // Create a new campaign
  CreateCampaign { target: Int, deadline: Int }
  // Withdraw funds (by campaign owner after deadline or verification)
  WithdrawFunds { campaign_id: ByteArray }
  // Verify a campaign by a medical professional
  VerifyCampaign { campaign_id: ByteArray, document_hash: ByteArray }
  // Cancel a campaign (owner or governance decision)
  CancelCampaign { campaign_id: ByteArray }
}
