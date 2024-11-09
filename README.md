# Overview

This is an example nft market project. User can create his own nft, add a picture and set initial USDC price.

## Project Features:

1. Runs github action on pull request and push to run tests and check formatting.
1. Runs husky on pre-commit

## NFT Contract Features

- **ERC721 Token Standard**: Implements the `ERC721URIStorageUpgradeable` standard for minting and managing NFTs.
- **Ownership and Access Control**: Inherits `OwnableUpgradeable`, with the contract owner having special administrative rights (e.g., setting fees and withdrawing collected fees).
- **Token Creation**: Allows users to create new NFTs with a specified URI (metadata) and an initial price in USDT (Tether).
- **Token Buying**: Users can buy NFTs by paying with USDT, including handling transaction fees and updating token ownership.
- **Price Setting**: Token owners can set or change the price of their tokens.
- **Fee Collection**: A fee (in percentage) is collected on each transaction and transferred to the contract address.
- **Default Price Increase**: The price of tokens increases by a default percentage after each sale.
- **Transfer Ownership**: Token owners can transfer their NFTs to other users.
- **Fee Withdrawal**: The contract owner can withdraw accumulated fees from the contract.
- **USDT Integration**: Integrates with the USDT (Tether) token for payments and fees, ensuring transactions use the ERC20 USDT contract.
- **Security Errors**: Includes various custom error messages (e.g., `NonExistingToken`, `NotTokenOwner`, `TokenNotForSale`) for better error handling.
- **Events**: Emits events for actions like token creation, token purchase, price changes, and fee withdrawals, providing transparency and tracking.
- **Upgradeable**: Uses OpenZeppelin's upgradeable contract libraries, allowing for future contract upgrades without losing state.
