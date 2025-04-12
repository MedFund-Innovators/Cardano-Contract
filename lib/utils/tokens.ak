use aiken/crypto.{VerificationKeyHash}
use aiken/primitive/bytearray
use types/token.{
  bronze_tier, gold_tier, mednft_prefix, platinum_tier, silver_tier,
}

/// Token utility functions for MedFund
/// Generate unique NFT name based on campaign ID and donor
pub fn generate_nft_name(
  campaign_id: ByteArray,
  donor: VerificationKeyHash,
  amount: Int,
) -> ByteArray {
  let tier =
    if amount >= platinum_tier {
      // "Platinum"
      #"506c6174696e756d"
    } else if amount >= gold_tier {
      // "Gold"
      #"476f6c64"
    } else if amount >= silver_tier {
      // "Silver"
      #"53696c766572"
    } else {
      // "Bronze"
      #"42726f6e7a65"
    }
  bytearray.concat(
    mednft_prefix,
    bytearray.concat(campaign_id, bytearray.concat(tier, donor)),
  )
}
