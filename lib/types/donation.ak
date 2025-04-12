use aiken/crypto.{Blake2b_224, Hash, VerificationKeyHash}
use types/campaign.{Campaign}

/// Donation related types for the MedFund platform
/// Donation data structure
pub type DonationDatum {
  campaign_id: ByteArray,
  donor: VerificationKeyHash,
  amount: Int,
}

/// Donation actions
pub type DonationAction {
  // Donate to a campaign
  Donate { campaign_id: ByteArray, amount: Int }
  // Request refund (if campaign cancelled or deadline passed without meeting target)
  RequestRefund { campaign_id: ByteArray }
}
