# Complete Deployment Guide

## 🚀 Quick Start - 3 Ways to Deploy

### Option 1: Automated Deployment (Easiest)

```bash
# One command to prepare everything
./deploy-automated.sh devnet

# Then deploy
clarinet integrate
```

### Option 2: Quick Deploy Script

```bash
# All-in-one deployment
./quick-deploy.sh
```

### Option 3: Manual Step-by-Step

```bash
# 1. Check contracts
clarinet check

# 2. Start console
clarinet console

# 3. Deploy each contract
(contract-call? .contract-name ...)
```

---

## 📋 Deployment Scripts Overview

### 1. `deploy-automated.sh` - Main Deployment Script

**Purpose**: Comprehensive automated deployment with checks and validation

**Usage**:

```bash
./deploy-automated.sh [devnet|testnet|mainnet]
```

**Features**:

- ✅ Prerequisites checking
- ✅ Network validation
- ✅ Syntax verification
- ✅ Deployment plan generation
- ✅ Documentation creation
- ✅ Safety checks for mainnet

**Example**:

```bash
# Deploy to devnet
./deploy-automated.sh devnet

# Prepare testnet deployment
./deploy-automated.sh testnet

# Mainnet (blocked by safety check)
./deploy-automated.sh mainnet
```

### 2. `quick-deploy.sh` - Fast Deployment

**Purpose**: Quick one-command deployment for development

**Usage**:

```bash
./quick-deploy.sh
```

**What it does**:

1. Checks if Clarinet is running
2. Starts devnet if needed
3. Runs automated deployment
4. Shows next steps

### 3. `verify-deployment.sh` - Verification

**Purpose**: Verify all contracts are ready/deployed

**Usage**:

```bash
./verify-deployment.sh [network] [deployer-address]
```

**Example**:

```bash
# Verify devnet deployment
./verify-deployment.sh devnet

# Verify testnet deployment
./verify-deployment.sh testnet ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
```

---

## 🎯 Step-by-Step Deployment

### Step 1: Prepare Environment

```bash
# Install Clarinet (if not installed)
# Visit: https://docs.stacks.co/clarinet

# Verify installation
clarinet --version

# Navigate to project
cd stacks-monorepo
```

### Step 2: Review Contracts

```bash
# Check all contracts
clarinet check

# Review specific contract
cat contracts/lottery-system.clar
```

### Step 3: Choose Deployment Method

#### A. Devnet (Local Testing)

```bash
# Method 1: Automated
./deploy-automated.sh devnet
clarinet integrate

# Method 2: Console
clarinet console
# Then deploy interactively
```

#### B. Testnet (Public Testing)

```bash
# 1. Get testnet STX
# Visit: https://explorer.stacks.co/sandbox/faucet

# 2. Configure wallet
export STACKS_PRIVATE_KEY="your-key-here"

# 3. Generate deployment
clarinet deployments generate --testnet

# 4. Review plan
cat deployments/default.testnet-plan.yaml

# 5. Deploy
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

#### C. Mainnet (Production)

```bash
# ⚠️ ONLY AFTER SECURITY AUDIT ⚠️

# 1. Complete audit
# 2. Test thoroughly on testnet
# 3. Prepare emergency procedures
# 4. Generate deployment
clarinet deployments generate --mainnet

# 5. Review carefully
cat deployments/default.mainnet-plan.yaml

# 6. Deploy (irreversible!)
clarinet deployments apply -p deployments/default.mainnet-plan.yaml
```

### Step 4: Verify Deployment

```bash
# Run verification script
./verify-deployment.sh devnet

# Or check manually
clarinet console
::get_contracts
```

### Step 5: Test Contracts

```bash
# Run test suite
npm install
npm test

# Manual testing
clarinet console
(contract-call? .lottery-system start-lottery)
```

---

## 📦 Contract Deployment Order

The automated system deploys in this order:

1. **nft-marketplace** (5,173 bytes)
   - Independent NFT system
   - No dependencies

2. **oracle-feed** (3,683 bytes)
   - Data provider
   - No dependencies

3. **lottery-system** (5,135 bytes)
   - Standalone lottery
   - No dependencies

4. **time-locked-vault** (4,342 bytes)
   - Time-based locking
   - No dependencies

5. **multi-sig-wallet** (4,744 bytes)
   - Multi-signature wallet
   - No dependencies

6. **crowdfunding** (5,551 bytes)
   - Campaign funding
   - No dependencies

7. **dao-governance** (5,523 bytes)
   - Governance system
   - No dependencies

8. **escrow-service** (5,446 bytes)
   - P2P escrow
   - No dependencies

9. **staking-pool** (5,094 bytes)
   - Staking rewards
   - No dependencies

10. **token-vault** (5,962 bytes)
    - Token storage
    - No dependencies

**Total Size**: ~50KB of smart contract code

---

## 🔧 Configuration

### Environment Variables

```bash
# Deployer address
export STACKS_DEPLOYER_ADDRESS="ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"

# Network
export STACKS_NETWORK="devnet"

# Private key (testnet/mainnet only)
export STACKS_PRIVATE_KEY="your-private-key"

# API endpoint
export STACKS_API_URL="https://stacks-node-api.testnet.stacks.co"
```

### Clarinet Configuration

Edit `Clarinet.toml` to customize:

```toml
[project]
name = "stacks-monorepo"
requirements = []

[contracts.lottery-system]
path = "contracts/lottery-system.clar"
clarity_version = 2
```

---

## 💰 Deployment Costs

### Devnet

- **Cost**: FREE
- **Tokens**: Unlimited test STX
- **Purpose**: Development and testing

### Testnet

- **Cost**: FREE
- **Tokens**: Free from faucet
- **Purpose**: Public testing

### Mainnet

- **Estimated Costs**:
  - Small contract (~3KB): ~0.5 STX
  - Medium contract (~5KB): ~1.0 STX
  - Large contract (~10KB): ~2.0 STX

- **Total for 10 contracts**: ~10-15 STX
- **Current value**: Check STX price

---

## 🛡️ Security Checklist

### Before Deployment

- [ ] Code review completed
- [ ] Security audit performed
- [ ] All tests passing
- [ ] Devnet testing successful
- [ ] Testnet testing successful
- [ ] Documentation complete
- [ ] Emergency procedures documented
- [ ] Monitoring setup ready
- [ ] Bug bounty program active
- [ ] Legal review completed

### After Deployment

- [ ] Contracts verified on explorer
- [ ] Basic functions tested
- [ ] Monitoring active
- [ ] Team notified
- [ ] Documentation updated
- [ ] Community announced

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "as-contract not found"

**Problem**: Contracts use Clarity 2 features
**Solution**:

```bash
# Update Clarinet
brew upgrade clarinet

# Or download latest from GitHub
```

#### 2. "Insufficient funds"

**Problem**: Not enough STX for deployment
**Solution**:

```bash
# Devnet: Use default accounts
# Testnet: Get from faucet
# Mainnet: Fund your wallet
```

#### 3. "Contract already exists"

**Problem**: Contract name collision
**Solution**:

```bash
# Use different contract name
# Or deploy from different address
```

#### 4. "Transaction failed"

**Problem**: Contract error or invalid parameters
**Solution**:

```bash
# Check syntax
clarinet check

# Review error message
# Test on devnet first
```

---

## 📊 Monitoring Deployment

### During Deployment

```bash
# Watch deployment progress
tail -f deployment.log

# Check transaction status
clarinet console
::get_transaction <tx-id>
```

### After Deployment

```bash
# Verify on explorer
# Testnet: https://explorer.stacks.co/?chain=testnet
# Mainnet: https://explorer.stacks.co/

# Check contract
clarinet console
::get_contract_source <address>.<contract>
```

---

## 📚 Additional Resources

### Documentation

- [Clarinet Documentation](https://docs.stacks.co/clarinet)
- [Clarity Language Reference](https://docs.stacks.co/clarity)
- [Stacks Blockchain](https://www.stacks.co/)

### Tools

- [Stacks Explorer](https://explorer.stacks.co/)
- [Testnet Faucet](https://explorer.stacks.co/sandbox/faucet)
- [Stacks CLI](https://github.com/hirosystems/stacks.js)

### Community

- [Discord](https://discord.gg/stacks)
- [Forum](https://forum.stacks.org/)
- [GitHub](https://github.com/stacks-network)

---

## 🎉 Success!

Once deployed, your contracts are live on the Stacks blockchain!

**Next Steps**:

1. Test all contract functions
2. Monitor for issues
3. Update documentation
4. Announce to community
5. Build frontend integration

---

**Need Help?** Open an issue or join the Stacks Discord!
