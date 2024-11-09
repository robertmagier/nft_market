# NFT Contracts Project

This project is a Solidity-based smart contract system that enables minting, buying, and transferring NFTs, as well as managing associated fees. It uses the Hardhat framework and OpenZeppelin's upgradeable contracts to ensure flexibility and security for NFT operations.

## Prerequisites

Ensure you have the following installed:

- **Node.js** (>= 16.x recommended)
- **npm** or **yarn**
- **Hardhat CLI**: Install Hardhat globally if it’s not already installed:
  ```bash
  npm install -g hardhat
  ```

## Project Setup

1. Clone the repository:

   ```bash
   git clone <repository_url>
   cd nft-contracts
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Configuration

To deploy the contract, configure your network and wallet information in the `hardhat.config.js` file. Add network configurations (like for testnets or mainnet) using environment variables or directly in `hardhat.config.js`.

Example for network configuration in `hardhat.config.js`:

```javascript
module.exports = {
  solidity: '0.8.27',
  networks: {
    hardhat: {},
    rinkeby: {
      url: process.env.RINKEBY_URL || '',
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
```

### Environment Variables

If you’re using test networks or mainnet, create a `.env` file in the root directory with network URL and private key:

```env
RINKEBY_URL="https://eth-rinkeby.alchemyapi.io/v2/YOUR_ALCHEMY_KEY"
PRIVATE_KEY="your-private-key-here"
```

## Compiling Contracts

To compile the contracts, use:

```bash
npx hardhat compile
```

This command will compile all smart contracts in the `contracts` folder and generate TypeScript typings.

## Running Tests

To run tests:

```bash
npx hardhat test
```

This command runs tests in the `test` folder and shows results in the console.

## Deploying Contracts

To deploy the contract, create a deployment script in the `scripts` directory. Below is an example for deploying the `Nft.sol` contract.

**Example script (`scripts/deploy.js`):**

```javascript
async function main() {
  const NFT = await ethers.getContractFactory('Nft');
  const nft = await NFT.deploy();
  await nft.deployed();
  console.log('NFT Contract deployed to:', nft.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Run the deployment script with:

```bash
npx hardhat run scripts/deploy.js --network <network_name>
```

Replace `<network_name>` with your chosen network (e.g., `rinkeby`, `ropsten`, or `mainnet`).

## Interacting with the Contract

You can interact with the contract using Hardhat tasks or the Hardhat console:

```bash
npx hardhat console --network <network_name>
```

### Example Commands

- **Mint a New Token**:

  ```javascript
  const nft = await ethers.getContractAt('Nft', '<nft_contract_address>');
  await nft.create(
    'https://my-nft-metadata-url.com',
    ethers.utils.parseUnits('10', 6)
  ); // 10 USDT
  ```

- **Buy a Token**:

  ```javascript
  await nft.buy(tokenId);
  ```

- **Set a New Price**:

  ```javascript
  await nft.setPrice(tokenId, ethers.utils.parseUnits('15', 6)); // Set to 15 USDT
  ```

- **Withdraw Collected Fees**:
  ```javascript
  await nft.withdrawFees();
  ```

## Additional Commands

### Compilation & Type Generation

To compile and generate TypeScript types:

```bash
npm run build
```

This command runs both compilation and type generation steps defined in your `package.json`.

## License

This project is licensed under the MIT License.

---

**Security Disclaimer**: Test your contracts thoroughly on test networks before deploying to mainnet. Be aware of Ethereum mainnet fees and associated risks. This smart contract was not audited. 

**Contact**: Reach out if you have questions or encounter issues.
