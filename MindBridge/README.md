# Mind Bridge Fund

A decentralized mental health support fund built with Clarity smart contracts that enables community-driven funding for mental health initiatives and individual assistance.

## Overview

Mind Bridge Fund addresses the accessibility gap in mental health support by creating a transparent, community-governed funding mechanism. Contributors donate to a shared pool and democratically vote on funding proposals for therapy sessions, support groups, crisis intervention, and mental health research.

## Features

- **Community-Driven Funding**: Decentralized donation pool for mental health support
- **Democratic Governance**: Weighted voting system based on contribution history
- **Diverse Support Categories**: Therapy, support groups, crisis intervention, research
- **Reputation System**: Contributors build reputation through participation
- **Transparent Process**: All proposals and decisions recorded on-chain
- **Flexible Funding**: Support amounts from 1,000 to 50,000 units

## Quick Start

### Making a Donation

```clarity
;; Donate 5000 units to the fund
(contract-call? .mind-bridge-fund donate-to-fund u5000)
```

### Submitting a Proposal

```clarity
;; Request funding for therapy sessions
(contract-call? .mind-bridge-fund submit-proposal 
  "Individual Therapy Support"
  "Funding for 10 therapy sessions for anxiety treatment"
  u3000
  "Individual Therapy")
```

### Voting on Proposals

```clarity
;; Vote in favor of proposal #1
(contract-call? .mind-bridge-fund vote-on-proposal u1 true)
```

## Core Functions

| Function | Access | Description |
|----------|--------|-------------|
| `donate-to-fund` | Public | Contribute funds to the pool |
| `submit-proposal` | Public | Request funding for mental health support |
| `vote-on-proposal` | Contributors | Vote on funding proposals |
| `finalize-proposal` | Public | Execute completed votes |
| `emergency-withdraw` | Owner | Emergency fund access |

## Funding Categories

- **Individual Therapy** - Personal counseling sessions
- **Support Groups** - Community mental health groups
- **Crisis Intervention** - Emergency mental health support
- **Research** - Mental health research initiatives
- **Awareness** - Community education campaigns
- **Training** - Mental health advocate training

## Governance Model

### Voting Power
- Base voting power: 1 vote
- Additional power: +1 vote per 1,000 units donated
- Example: 5,000 donation = 6 total votes

### Proposal Requirements
- **Minimum Amount**: 1,000 units
- **Maximum Amount**: 50,000 units
- **Voting Period**: 1 week (1,008 blocks)
- **Approval Threshold**: 60% support + minimum 10 votes

### Reputation System
Contributors earn reputation through:
- Making donations (+1 per donation)
- Participating in votes (+1 per vote)
- Higher reputation enables community leadership

## Error Codes

- `u401` - Unauthorized access
- `u402` - Insufficient funds
- `u403` - Invalid amount
- `u404` - Proposal not found
- `u405` - Voting period closed
- `u406` - Already voted
- `u407` - Proposal not active

## Use Cases

### Individual Support
- Therapy session funding for those unable to afford treatment
- Crisis intervention support during mental health emergencies
- Medication assistance for low-income individuals

### Community Initiatives
- Support group startup funding
- Mental health awareness campaigns
- Training programs for peer counselors

### Research & Development
- Community-based mental health research
- Development of accessible mental health tools
- Studies on effective intervention methods

## Security Features

- **Contributor Verification**: Only donors can vote
- **Time-Limited Voting**: Prevents indefinite proposal states
- **Amount Limits**: Prevents excessive single proposals
- **Emergency Controls**: Owner can intervene in critical situations
- **Transparent Records**: All transactions and votes on-chain

## Getting Started

1. **Contributors**: Donate to build voting power and support the cause
2. **Applicants**: Submit detailed proposals with clear mental health impact
3. **Community**: Review and vote on proposals that align with fund mission
4. **Recipients**: Use approved funding responsibly for stated mental health purposes

## Impact Tracking

The contract automatically tracks:
- Total funds raised and distributed
- Number of proposals funded
- Individual recipient history
- Community participation metrics

## Contributing

This project welcomes contributions focused on:
- Enhanced proposal categorization
- Improved voting mechanisms
- Integration with mental health resources
- Community governance features