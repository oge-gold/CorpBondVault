# CorpBondVault

A sophisticated synthetic assets platform that creates tokenized exposure to traditional corporate bond portfolios on the Stacks blockchain. CorpBondVault enables users to gain synthetic exposure to diversified corporate bond investments through collateralized synthetic tokens.

## Features

- **Synthetic Corporate Bond Exposure**: Create tokenized synthetic positions that track real corporate bond portfolio performance
- **Collateralized Minting**: Mint synthetic tokens by depositing STX as collateral with configurable collateral ratios
- **Multi-Portfolio Support**: Multiple corporate bond portfolios with different risk profiles and target yields
- **Oracle-Based Pricing**: Real-time price feeds from authorized oracles for accurate portfolio valuations
- **SIP-010 Compliance**: Full compatibility with Stacks fungible token standard
- **Risk Management**: Built-in collateral ratio requirements and price freshness checks
- **Administrative Controls**: Secure portfolio creation and oracle management

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Token Standard**: SIP-010 Fungible Token
- **Epoch**: 2.5
- **Default Collateral Ratio**: 120% (12,000 basis points)
- **Platform Fee**: 1% (100 basis points)
- **Token Decimals**: 6
- **Price Validity**: 24 hours (144 blocks)

## Architecture

### Core Components

1. **CBV Token**: The fungible token representing synthetic corporate bond exposure
2. **Portfolio System**: Manages different corporate bond portfolio configurations
3. **Oracle Network**: Provides real-time pricing data for portfolios
4. **Collateral Management**: Handles STX deposits and withdrawals
5. **Position Tracking**: Records user synthetic positions and collateral

### Key Data Structures

- **Portfolios**: Portfolio metadata including name, yield targets, and risk ratings
- **Portfolio Prices**: Real-time pricing data with oracle attribution
- **User Positions**: Individual user synthetic token positions and collateral
- **Authorized Oracles**: Approved price feed providers

## Installation

### Prerequisites

- [Clarinet CLI](https://github.com/hirosystems/clarinet) installed
- Node.js (v16 or higher)
- Stacks wallet for testnet/mainnet deployment

### Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd CorpBondVault
   ```

2. **Install dependencies**:
   ```bash
   cd CorpBondVault_contract
   npm install
   ```

3. **Run tests**:
   ```bash
   npm test
   ```

4. **Start local development**:
   ```bash
   clarinet console
   ```

## Usage Examples

### For Users

#### Mint Synthetic Tokens
```clarity
;; Mint 1000 synthetic tokens for portfolio ID 1 with 2000 STX collateral
(contract-call? .CorpBondVault mint-synthetic u1 u1000000 u2000000000)
```

#### Burn Synthetic Tokens
```clarity
;; Burn 500 synthetic tokens from portfolio ID 1
(contract-call? .CorpBondVault burn-synthetic u1 u500000)
```

#### Check Position
```clarity
;; Get user position for portfolio ID 1
(contract-call? .CorpBondVault get-user-position 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE u1)
```

### For Administrators

#### Create Portfolio
```clarity
;; Create a new corporate bond portfolio
(contract-call? .CorpBondVault create-portfolio 
  u1 
  "Investment Grade Corps" 
  "Diversified investment grade corporate bonds with 3-5 year maturity"
  u450  ;; 4.5% target yield
  u3    ;; Risk rating 3
)
```

#### Add Oracle
```clarity
;; Authorize a new price oracle
(contract-call? .CorpBondVault add-oracle 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)
```

### For Oracles

#### Update Portfolio Price
```clarity
;; Update portfolio price (oracle only)
(contract-call? .CorpBondVault update-portfolio-price u1 u1050000) ;; $1.05 per unit
```

## Contract Functions Documentation

### Public Functions

#### SIP-010 Standard Functions
- `transfer(amount, from, to, memo)` - Transfer tokens between addresses
- `get-name()` - Returns token name
- `get-symbol()` - Returns token symbol  
- `get-decimals()` - Returns token decimals
- `get-balance(user)` - Returns user token balance
- `get-total-supply()` - Returns total token supply
- `get-token-uri()` - Returns token metadata URI

#### Administrative Functions
- `set-contract-admin(new-admin)` - Transfer admin rights
- `add-oracle(oracle)` - Authorize price oracle
- `remove-oracle(oracle)` - Revoke oracle authorization
- `create-portfolio(...)` - Create new bond portfolio
- `toggle-portfolio-status(portfolio-id)` - Activate/deactivate portfolio

#### Core Platform Functions
- `mint-synthetic(portfolio-id, amount, collateral)` - Mint synthetic tokens
- `burn-synthetic(portfolio-id, amount)` - Burn synthetic tokens for collateral
- `update-portfolio-price(portfolio-id, new-price)` - Update portfolio pricing (oracle only)

### Read-Only Functions

- `get-portfolio(portfolio-id)` - Retrieve portfolio information
- `get-portfolio-price(portfolio-id)` - Get current portfolio price
- `get-user-position(user, portfolio-id)` - Get user's position details
- `get-contract-admin()` - Get current admin address
- `is-authorized-oracle(oracle)` - Check oracle authorization
- `calculate-collateral-ratio(user, portfolio-id)` - Calculate user's collateral ratio
- `get-platform-fee()` - Get current platform fee
- `get-min-collateral-ratio()` - Get minimum collateral requirement

## Deployment Guide

### Testnet Deployment

1. **Configure testnet settings**:
   ```bash
   clarinet deployments generate --testnet
   ```

2. **Deploy to testnet**:
   ```bash
   clarinet deployments apply --testnet
   ```

### Mainnet Deployment

1. **Update mainnet configuration** in `settings/Mainnet.toml`

2. **Generate deployment plan**:
   ```bash
   clarinet deployments generate --mainnet
   ```

3. **Deploy to mainnet**:
   ```bash
   clarinet deployments apply --mainnet
   ```

### Post-Deployment Setup

1. **Configure initial portfolios**
2. **Add authorized oracles**
3. **Set appropriate collateral ratios**
4. **Initialize price feeds**

## Security Notes

### Risk Considerations

- **Oracle Dependency**: Platform relies on external oracles for pricing; oracle failures could impact operations
- **Collateral Risk**: Users face liquidation risk if collateral ratios fall below requirements
- **Smart Contract Risk**: As with all DeFi protocols, smart contract bugs could result in loss of funds
- **Price Lag**: 24-hour price validity window may not capture rapid market movements

### Security Features

- **Over-collateralization**: 120% minimum collateral ratio provides buffer against price volatility
- **Time-based Price Validation**: Prices must be updated within 24 hours to prevent stale data usage
- **Administrative Controls**: Multi-level access controls for sensitive operations
- **Input Validation**: Comprehensive checks on user inputs and contract state

### Best Practices

- **Regular Monitoring**: Users should monitor collateral ratios and market conditions
- **Oracle Diversification**: Multiple authorized oracles reduce single points of failure  
- **Gradual Position Building**: Consider building positions gradually to manage risk
- **Understanding Synthetic Exposure**: Users should understand they hold synthetic exposure, not direct bond ownership

## Testing

The project includes comprehensive test coverage using Vitest and Clarinet SDK:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

ISC License - see LICENSE file for details.

## Support

For questions, issues, or support:
- Create an issue in the GitHub repository
- Review the contract documentation
- Check existing tests for usage examples

---

**Disclaimer**: This smart contract facilitates synthetic exposure to corporate bond portfolios and involves financial risk. Users should understand the mechanics and risks before participating. This is not financial advice.