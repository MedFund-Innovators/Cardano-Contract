use aiken/crypto.{Blake2b_224, Hash, VerificationKeyHash}

/// Common types used across validators
/// Milestone representing a funding target with associated proof
pub type Milestone {
  description: ByteArray,
  amount: Int,
  completed: Bool,
  proof_hash: Option<Hash<Blake2b_224, ByteArray>>,
}

/// Campaign status
pub type CampaignStatus {
  Active
  Completed
  Cancelled
}

/// Campaign data structure
pub type Campaign {
  patient_id: ByteArray,
  medical_proof_hash: Hash<Blake2b_224, ByteArray>,
  funding_goal: Int,
  timeline: Int,
  healthcare_provider: VerificationKeyHash,
  milestones: List<Milestone>,
  total_raised: Int,
  status: CampaignStatus,
}

/// MedToken parameters for minting
pub type MedTokenParams {
  campaign_id: Hash<Blake2b_224, Campaign>,
  donation_amount: Int,
  token_amount: Int,
}
