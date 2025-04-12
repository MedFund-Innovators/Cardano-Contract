# MedFund: A Blockchain-Based Healthcare Crowdfunding Platform

## Overview

MedFund is a decentralized crowdfunding platform built on Cardano that enables transparent, secure, and low-cost healthcare fundraising. It connects patients in need with donors globally, ensuring trust and accountability through blockchain technology.

## Problem Statement

- Many Africans struggle to afford medical treatments, surgeries, or emergency healthcare
- Traditional crowdfunding platforms lack transparency, and donors often don't know how their funds are used
- High transaction fees and inefficiencies in cross-border donations

## Technical Architecture

MedFund leverages Aiken, a modern smart contract language for the Cardano blockchain. Aiken provides:

- A purely functional language with static typing and type inference
- Simple, auditable smart contracts that compile to Plutus Core
- Built-in testing capabilities for reliable contract validation
- Excellent developer experience with friendly error messages

### Aiken Syntax Notes

In Aiken:
- Validators use the `validator` keyword and handlers don't need the `fn` keyword
- Regular helper functions use the `fn` keyword with return type annotations
- Types are defined with the `type` keyword

### Smart Contract Structure

The core of MedFund consists of several Aiken validators:

```aiken
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext, Transaction}
use aiken/transaction/credential.{VerificationKey, VerificationKeyHash}

pub type Campaign {
  patient_id: ByteArray,
  medical_proof_hash: Hash<Blake2b_224, ByteArray>,
  funding_goal: Int,
  timeline: Int,
  healthcare_provider: VerificationKeyHash,
  milestones: List<Milestone>,
}

pub type Milestone {
  description: ByteArray,
  amount: Int,
  completed: Bool,
}

pub type DonationDatum {
  campaign_id: Hash<Blake2b_224, Campaign>,
  donor: VerificationKeyHash,
  amount: Int,
}

pub type CampaignRedeemer {
  action: CampaignAction,
}

pub type CampaignAction {
  CreateCampaign
  CompleteMilestone { milestone_index: Int, proof_hash: Hash<Blake2b_224, ByteArray> }
  WithdrawFunds { milestone_index: Int }
  CancelCampaign
}

validator campaign_validator {
  spend(datum: Campaign, redeemer: CampaignRedeemer, context: ScriptContext) {
    // Campaign validation logic
    // ...
  }
}

validator donation_validator {
  spend(datum: DonationDatum, _redeemer: Data, context: ScriptContext) {
    // Donation validation logic
    // ...
  }
}
```

## Key Features

### 1. Transparent Donations

**Smart Contracts**: We use Aiken validators to ensure funds are released only when specific medical milestones are met and verified.

```aiken
// Example milestone completion validation
let milestone = list.at(datum.milestones, redeemer.milestone_index)?
let proof_is_valid = verify_medical_proof(redeemer.proof_hash)
let provider_signed = list.has(context.transaction.extra_signatories, datum.healthcare_provider)

and {
  proof_is_valid,
  provider_signed,
}
```

### 2. Low-Cost Transactions

The platform leverages Cardano's inherently low transaction fees to make micro-donations feasible. Our smart contracts minimize on-chain operations to keep costs down.

### 3. Verifiable Campaigns

All campaigns require proof of medical need, verified on-chain through our validator scripts:

```aiken
fn verify_campaign(campaign: Campaign, context: ScriptContext) -> Bool {
  // Verify patient identity and medical proof
  let patient_verified = verify_patient_id(campaign.patient_id)
  let medical_proof_valid = verify_medical_proof(campaign.medical_proof_hash)
  
  and {
    patient_verified,
    medical_proof_valid,
  }
}
```

### 4. Decentralized Governance

```aiken
pub type GovernanceAction {
  EmergencyFundRelease { campaign_id: Hash<Blake2b_224, Campaign> }
  UpdateProtocol { new_parameters: ProtocolParameters }
}

pub type VoteDatum {
  governance_action: GovernanceAction,
  votes: Map<VerificationKeyHash, Bool>,
  quorum: Int,
}

validator governance_validator {
  spend(datum: VoteDatum, _redeemer: Data, context: ScriptContext) {
    // Governance validation logic
    // ...
  }
}
```

### 5. Incentivization

NFT "MedNFT tokens" are minted as rewards for donors:

```aiken
validator token_policy {
  mint(redeemer: Data, context: ScriptContext) {
    // Minting policy logic for donor rewards
    // ...
  }
}
```

## Getting Started

### Prerequisites

- Install Aiken: Follow the [official installation guide](https://aiken-lang.org/)
- Cardano node setup (for testing and deployment)

### Build and Test

```bash
# Initialize a new Aiken project
aiken new medfund

# Build the contracts
cd medfund
aiken build

# Run the tests
aiken check
```

## How It Works

### Step 1: Campaign Creation
A patient or their representative creates a campaign on MedFund, providing:
- Verified identity (using Atala PRISM)
- Medical proof (diagnosis, treatment plan)
- Funding goal and timeline

### Step 2: Donation Process
- Donors contribute ADA or Cardano Native Tokens to the campaign
- Funds are held in smart contracts until conditions are met

### Step 3: Fund Release
- Funds are released to healthcare providers in stages based on milestones
- Each milestone requires verification by the healthcare provider

### Step 4: Post-Campaign Transparency
- Treatment completion evidence is submitted on-chain
- Full transaction history remains visible for verification

## Roadmap

- Q1: Core smart contract development
- Q2: Front-end interface and testing
- Q3: Integration with Atala PRISM for identity verification
- Q4: Launch beta on Cardano testnet
- Q1 (Next Year): Mainnet launch

medfund/
├── validators/
│   ├── campaign.ak            # Main campaign validator
│   ├── donation.ak           # Donation handling validator
│   ├── governance.ak         # Governance and voting validator
│   └── token_policy.ak       # MedToken minting policy
│
├── lib/
│   ├── types/
│   │   ├── campaign.ak       # Campaign related types
│   │   ├── donation.ak       # Donation related types
│   │   ├── governance.ak     # Governance related types
│   │   └── common.ak         # Shared types
│   │
│   ├── utils/
│   │   ├── verification.ak   # Verification helper functions
│   │   ├── math.ak          # Math helper functions
│   │   └── constants.ak      # Constants used across validators
│   │
│   └── protocols/
│       ├── medical_proof.ak  # Medical proof verification protocol
│       └── milestone.ak      # Milestone management protocol
│
└── tests/
    ├── campaign_test.ak
    ├── donation_test.ak
    ├── governance_test.ak
    └── token_policy_test.ak

## Contributing

We welcome contributions! See our [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

