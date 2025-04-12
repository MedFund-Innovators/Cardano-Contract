use aiken/crypto.{VerificationKeyHash}

/// Token related types for the MedFund platform
/// MedNFT token parameters
pub type MedTokenParams {
  campaign_id: ByteArray,
  donor: VerificationKeyHash,
  amount: Int,
}

// 10 ADA
/// Donation tiers for NFT rewards (in lovelace)
pub const bronze_tier = 10000000

// 50 ADA 
pub const silver_tier = 50000000

// 100 ADA
pub const gold_tier = 100000000

// 500 ADA
pub const platinum_tier = 500000000

// "MedNFT" in hex
/// Token name prefix for MedNFT
pub const mednft_prefix = #"4d65644e4654"
