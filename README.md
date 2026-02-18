# Stacks Blockchain Smart Contracts Monorepo

A comprehensive collection of 10 production-ready smart contracts for the Stacks blockchain, built with Clarity.

## 🚀 Contracts Overview

### 1. Lottery System

A decentralized lottery where users can buy tickets and winners are selected randomly.

- Buy lottery tickets
- Random winner selection using VRF
- Automatic prize distribution
- Configurable ticket prices

### 2. NFT Marketplace

A full-featured marketplace for trading NFTs with platform fees.

- Mint NFTs
- List NFTs for sale
- Buy/sell NFTs
- Platform fee management
- Price updates

### 3. Time-Locked Vault

Secure STX storage with time-based unlocking mechanisms.

- Create time-locked vaults
- Extend lock periods
- Add funds to existing vaults
- Withdraw after unlock

### 4. Multi-Signature Wallet

Secure wallet requiring multiple signatures for transactions.

- Add/remove signers
- Submit transactions
- Collect signatures
- Execute with threshold
- Configurable signature requirements

### 5. Crowdfunding

Create and manage crowdfunding campaigns with goal-based funding.

- Create campaigns with goals
- Contribute to campaigns
- Claim funds if successful
- Refund if goal not reached
- Time-based deadlines

### 6. DAO Governance

Decentralized autonomous organization with voting mechanisms.

- Join DAO with voting power
- Create proposals
- Vote on proposals
- Quorum-based execution
- Configurable voting periods

### 7. Escrow Service

Secure peer-to-peer transactions with arbiter support.

- Create escrow agreements
- Fund escrow
- Release to seller
- Refund to buyer
- Arbiter dispute resolution

### 8. Oracle Feed

Provide external data feeds to smart contracts.

- Create price feeds
- Update prices
- Data freshness validation
- Multiple oracle support
- Staleness detection

### 9. Staking Pool

Stake STX tokens and earn rewards over time.

- Stake STX
- Earn block-based rewards
- Claim rewards
- Unstake tokens
- Configurable reward rates

### 10. Token Vault

Secure storage and management of fungible tokens.

- Create token vaults
- Deposit/withdraw tokens
- Time-locked vaults
- Fungible token support
- Vault management

## 📦 Installation

```bash
# Clone the repository
git clone <repository-url>
cd stacks-monorepo

# Install dependencies
npm install
```

## 🛠️ Development

### Check Contracts

```bash
clarinet check
```

### Run Tests

```bash
npm test
```

### Console

```bash
clarinet console
```

## 🧪 Testing

Each contract comes with comprehensive test suites written in TypeScript using Vitest.

```bash
# Run all tests
npm test

# Run specific contract tests
npm test lottery-system
```

## 🚢 Deployment

### Testnet Deployment

```bash
clarinet deploy --testnet
```

### Mainnet Deployment

```bash
clarinet deploy --mainnet
```

## 📝 Contract Details

### Lottery System

- **File**: `contracts/lottery-system.clar`
- **Features**: Random winner selection, ticket purchasing, prize distribution
- **Use Cases**: Lotteries, raffles, prize draws

### NFT Marketplace

- **File**: `contracts/nft-marketplace.clar`
- **Features**: NFT minting, listing, buying, selling
- **Use Cases**: Digital art marketplaces, collectibles trading

### Time-Locked Vault

- **File**: `contracts/time-locked-vault.clar`
- **Features**: Time-based locks, vault management
- **Use Cases**: Savings, vesting schedules, trust funds

### Multi-Sig Wallet

- **File**: `contracts/multi-sig-wallet.clar`
- **Features**: Multiple signature requirements, transaction management
- **Use Cases**: Corporate wallets, shared accounts, security

### Crowdfunding

- **File**: `contracts/crowdfunding.clar`
- **Features**: Campaign creation, contributions, refunds
- **Use Cases**: Project funding, charity, community initiatives

### DAO Governance

- **File**: `contracts/dao-governance.clar`
- **Features**: Voting, proposals, quorum
- **Use Cases**: Decentralized organizations, community governance

### Escrow Service

- **File**: `contracts/escrow-service.clar`
- **Features**: Secure transactions, arbiter support
- **Use Cases**: P2P trading, freelance payments, secure deals

### Oracle Feed

- **File**: `contracts/oracle-feed.clar`
- **Features**: Price feeds, data validation
- **Use Cases**: DeFi protocols, price tracking, external data

### Staking Pool

- **File**: `contracts/staking-pool.clar`
- **Features**: Staking, rewards, claiming
- **Use Cases**: Yield farming, token staking, passive income

### Token Vault

- **File**: `contracts/token-vault.clar`
- **Features**: Token storage, time locks, vault management
- **Use Cases**: Token custody, vesting, secure storage

## 🔒 Security

All contracts have been designed with security best practices:

- Input validation
- Access control
- Reentrancy protection
- Integer overflow protection
- Proper error handling

## 📄 License

MIT License

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For questions and support, please open an issue in the repository.
