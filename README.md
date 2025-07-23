# FlowLend 💰

**Collateralized Payment Streaming Protocol on Stacks Blockchain**

FlowLend is a decentralized lending platform that enables secure, collateralized payment streams on the Stacks blockchain. Borrowers can create loan requests with STX collateral, and lenders can fund these loans to receive structured payments over time.

## 🚀 Features

- **Collateralized Lending**: All loans require 150% minimum collateral ratio for security
- **Payment Streaming**: Borrowers make regular payments over the loan duration
- **Automated Liquidation**: Undercollateralized loans can be liquidated to protect lenders
- **Late Payment Fees**: 10% fee applied to overdue payments
- **Flexible Terms**: Customizable loan amounts, interest rates, and payment schedules

## 📋 How It Works

### For Borrowers
1. **Create Loan Request**: Deposit STX collateral (≥150% of loan amount) and specify loan terms
2. **Get Funded**: Wait for a lender to fund your loan request
3. **Make Payments**: Send regular payments to the lender according to the schedule
4. **Reclaim Collateral**: Complete all payments to unlock your collateral

### For Lenders
1. **Browse Requests**: View available loan requests with collateral backing
2. **Fund Loans**: Transfer STX to borrowers to activate loans
3. **Receive Payments**: Get regular payments with interest from borrowers
4. **Liquidation Protection**: Claim collateral if borrower defaults

## 🛠 Contract Functions

### Core Functions

- `create-loan-request(amount, collateral, interest-rate, duration, payment-interval)`
- `fund-loan(loan-id)`
- `make-payment(loan-id)`
- `liquidate-loan(loan-id)`

### Read-Only Functions

- `get-loan(loan-id)`
- `get-payment-schedule(loan-id)`
- `get-current-collateral-ratio(loan-id)`
- `check-liquidation-needed(loan-id)`

## 📊 Key Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Min Collateral Ratio | 150% | Minimum collateral required for loan creation |
| Liquidation Threshold | 130% | Collateral ratio below which liquidation is possible |
| Late Payment Fee | 10% | Additional fee for overdue payments |
| Daily Blocks | 144 | Approximate blocks per day on Stacks |

## 🔐 Security Features

- **Over-collateralization**: All loans require 150% collateral backing
- **Liquidation Mechanism**: Protects lenders from undercollateralized positions
- **Admin Controls**: Protocol parameters can be adjusted by admin
- **Error Handling**: Comprehensive error codes for all failure scenarios

## 💡 Use Cases

- **Working Capital**: Businesses can access STX liquidity while keeping their holdings
- **Margin Trading**: Traders can leverage their STX positions
- **Emergency Funds**: Quick access to liquidity without selling crypto assets
- **Yield Generation**: STX holders can earn interest by funding loans

## 🏗 Technical Details

**Blockchain**: Stacks  
**Language**: Clarity Smart Contract  
**Token**: STX (native Stacks token)  

### Loan States
- `PENDING`: Loan request created, waiting for funding
- `ACTIVE`: Loan funded and payment schedule active
- `COMPLETED`: All payments made successfully
- `LIQUIDATED`: Loan liquidated due to insufficient collateral
- `DEFAULTED`: Loan in default status

## 🔄 Liquidation Process

When a loan's collateral ratio falls below 130%:
1. Anyone can call `liquidate-loan(loan-id)`
2. Collateral is transferred to the lender
3. Loan status changes to `LIQUIDATED`
4. Borrower loses collateral but debt is cleared

## ⚠️ Risks

- **Collateral Risk**: Borrowers may lose collateral if they cannot maintain required ratios
- **Interest Rate Risk**: Fixed interest rates may not reflect market changes
- **Liquidation Risk**: Rapid STX price movements could trigger unexpected liquidations
- **Smart Contract Risk**: Protocol is subject to smart contract vulnerabilities

## 🚀 Getting Started

1. Deploy the FlowLend contract to Stacks blockchain
2. Set appropriate protocol parameters via admin functions
3. Start creating loan requests or funding existing ones
4. Monitor collateral ratios and payment schedules

## 📄 License

This project is open source and available under the MIT License.

---

*FlowLend: Empowering decentralized lending through collateralized payment streams* 🌊💰
