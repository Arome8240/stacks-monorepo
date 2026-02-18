# Automated Deployment Guide

## Quick Start

### Deploy to Devnet (Local Testing)

```bash
./deploy-automated.sh devnet
```

### Deploy to Testnet

```bash
./deploy-automated.sh testnet
```

### Deploy to Mainnet (After Audit)

```bash
./deploy-automated.sh mainnet
```

## Deployment Methods

### Method 1: Automated Script (Recommended)

The `deploy-automated.sh` script handles the entire deployment process:

```bash
# Make executable
chmod +x deploy-automated.sh

# Deploy to devnet
./deploy-automated.sh devnet

# Deploy to testnet (requires configuration)
./deploy-automated.sh testnet
```

### Method 2: Clarinet Deployments

```bash
# Generate deployment plan
clarinet deployments generate --testnet

# Review the plan
cat deployments/default.testnet-plan.yaml

# Apply deployment
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

### Method 3: Manual Deployment via Console

```bash
# Start Clarinet console
clarinet console

# Deploy each contract manually
(contract-call? .contract-name function-name args)
```

## Pre-Deployment Checklist

### For Devnet

- [x] Clarinet installed
- [x] Contracts written
- [ ] Run `clarinet check`
- [ ] Start devnet: `clarinet integrate`

### For Testnet

- [ ] Testnet STX tokens acquired
- [ ] Wallet configured
- [ ] Private keys secured
- [ ] Deployment plan reviewed
- [ ] Test transactions prepared

### For Mainnet

- [ ] Professional security audit completed
- [ ] All tests passing
- [ ] Testnet deployment successful
- [ ] Emergency procedures documented
- [ ] Monitoring setup complete
- [ ] Bug bounty program active
- [ ] Legal review completed
- [ ] Insurance obtained

## Contract Deployment Order

The automated script deploys contracts in this order:

1. **nft-marketplace** - Independent NFT system
2. **oracle-feed** - Data provider (no dependencies)
3. **lottery-system** - Standalone lottery
4. **time-locked-vault** - Time-based locking
5. **multi-sig-wallet** - Multi-signature wallet
6. **crowdfunding** - Campaign funding
7. **dao-governance** - Governance system
8. **escrow-service** - P2P escrow
9. **staking-pool** - Staking rewards
10. **token-vault** - Token storage

## Environment Variables

```bash
# Set deployer address
export STACKS_DEPLOYER_ADDRESS="ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"

# Set network
export STACKS_NETWORK="testnet"

# Set private key (for testnet/mainnet)
export STACKS_PRIVATE_KEY="your-private-key-here"
```

## Deployment Configuration

### Clarinet.toml

The project's `Clarinet.toml` file contains all contract configurations:

```toml
[project]
name = "stacks-monorepo"
requirements = []

[contracts.lottery-system]
path = "contracts/lottery-system.clar"
clarity_version = 2

# ... (all 10 contracts configured)
```

### Network Settings

#### Devnet (settings/Devnet.toml)

- Local development
- Fast iteration
- No real funds

#### Testnet (settings/Testnet.toml)

- Public test network
- Free test tokens
- Real blockchain behavior

#### Mainnet (settings/Mainnet.toml)

- Production network
- Real STX tokens
- Permanent deployment

## Post-Deployment Steps

### 1. Verify Deployment

```bash
# Check contract on explorer
# Testnet: https://explorer.stacks.co/?chain=testnet
# Mainnet: https://explorer.stacks.co/

# Verify contract code
clarinet console
::get_contract_source <contract-address>.<contract-name>
```

### 2. Initialize Contracts

Some contracts may need initialization:

```clarity
;; Example: Add oracle to oracle-feed
(contract-call? .oracle-feed add-oracle 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Example: Start lottery
(contract-call? .lottery-system start-lottery)
```

### 3. Test Basic Functions

```bash
# Run integration tests
npm install
npm test

# Manual testing via console
clarinet console
```

### 4. Monitor Contracts

- Set up transaction monitoring
- Configure alerts for errors
- Track gas usage
- Monitor contract balance

## Troubleshooting

### Issue: "as-contract not found"

**Solution**: These contracts require Clarity 2. Ensure your Clarinet version supports it:

```bash
clarinet --version
# Should be 1.7.0 or higher
```

### Issue: "Insufficient funds"

**Solution**:

- Devnet: Use default accounts
- Testnet: Get free tokens from faucet
- Mainnet: Ensure wallet is funded

### Issue: "Contract already exists"

**Solution**:

- Use a different contract name
- Or deploy from a different address

### Issue: "Transaction failed"

**Solution**:

- Check contract syntax
- Verify function parameters
- Review error messages
- Test on devnet first

## Deployment Costs

### Testnet

- Free (use faucet for test STX)
- No real cost

### Mainnet

Estimated costs per contract:

- Small contract (~3KB): ~0.5 STX
- Medium contract (~5KB): ~1.0 STX
- Large contract (~10KB): ~2.0 STX

**Total estimated cost**: ~10-15 STX for all 10 contracts

## Security Considerations

### Before Deployment

1. **Code Review**: Multiple developers review
2. **Security Audit**: Professional audit firm
3. **Testing**: Comprehensive test coverage
4. **Simulation**: Test all scenarios
5. **Documentation**: Complete and accurate

### After Deployment

1. **Monitoring**: 24/7 contract monitoring
2. **Incident Response**: Clear procedures
3. **Bug Bounty**: Reward security researchers
4. **Insurance**: Consider smart contract insurance
5. **Updates**: Plan for upgrades if needed

## Automated Deployment Features

The `deploy-automated.sh` script provides:

✅ Prerequisites checking
✅ Network validation
✅ Syntax verification
✅ Deployment plan generation
✅ Progress tracking
✅ Error handling
✅ Deployment documentation
✅ Post-deployment checklist

## Support

For deployment issues:

1. Check Clarinet documentation
2. Review Stacks documentation
3. Join Stacks Discord
4. Open GitHub issue

## License

MIT License - See LICENSE file
