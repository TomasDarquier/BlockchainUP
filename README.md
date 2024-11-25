
# NFT Pawn Shop Smart Contract

This repository contains a Solidity smart contract that enables using NFTs as collateral for loans. It allows users to pawn NFTs, propose loans, and manage repayments.

---

## ✨ Features

- **Approve NFT Collections**: Only approved collections can be pawned, ensuring security and value.
- **Create Pawn Proposals**: Users list NFTs as collateral for potential loans.
- **Submit Loan Offers**: Lenders propose terms such as loan amount, interest rate, and duration.
- **Accept Offers**: NFT owners choose offers and lock their NFTs as collateral.
- **Repay Loans**: Owners repay within the agreed duration to recover their NFTs.
- **Claim Collateral**: Lenders claim NFTs if borrowers default.

---

## ⚙️ Technical Details

- **Solidity Version**: `0.8.7`
- **Dependencies**: [OpenZeppelin ERC1155 Contracts](https://docs.openzeppelin.com/contracts/4.x/erc1155)
- **State Management**:
  - **Enum `Estado`**: Tracks the pawn lifecycle (`CREATED`, `ACCEPTED`, `PAID`, `CANCELLED`, `EXPIRED`).
  - **Structs**:
    - **`Propuesta`**: Stores NFT details and proposal status.
    - **`OfertaDePrestamo`**: Records loan offer details like lender, amount, and interest.

---

## 🛠️ How It Works

1. **Approve Collections**: Contract owner specifies allowed NFT collections.
2. **List NFTs**: Owners transfer approved NFTs to the contract for listing.
3. **Make Offers**: Lenders propose loan terms (amount, interest, duration).
4. **Accept Offers**: Borrowers accept an offer and lock their NFT as collateral.
5. **Repayment**: Borrowers repay loans with interest to retrieve their NFTs.
6. **Default**: Lenders claim NFTs if loans are not repaid on time.

---

## 🚀 Deployment

1. Install dependencies for Solidity 0.8.7 and OpenZeppelin libraries.
2. Compile the contract using a compatible IDE or CLI tool.
3. Deploy the contract to an Ethereum-compatible network.

---

## ⚠️ Disclaimer

This contract is for **educational purposes** only. Use at your own risk. Test thoroughly before deploying to a production environment.
