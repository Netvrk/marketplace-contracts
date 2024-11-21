## Project Overview

This project implements a marketplace for NFTs (Non-Fungible Tokens) on the Ethereum blockchain. The marketplace allows users to create, cancel, and execute orders for NFTs. The project is built using Solidity and leverages OpenZeppelin's upgradeable contracts.

### Smart Contracts (ropsten Network)

- **NRGY**: 0x946803FAFa7cF519a163802cA44C17DE010E8cF7
- **AXE**: 0xfe9E31e7E34f8c41456782798d6D0683BA11eBd4
- **Market**: 0xFDeB0330eBcEA3840518e2E095C1235449DD8117

### Marketplace Contract

The main contract for the marketplace is [`MarketPlace`](contracts/Market.sol). This contract includes the following key features:

- **Order Management**: Users can create, cancel, and execute orders for NFTs.
- **Fees and Royalties**: The contract supports fees for the marketplace and royalties for the original creators of the NFTs.
- **Upgradeable**: The contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern to allow for future upgrades.

### Key Functions

- **initialize**: Initializes the contract with the accepted token, fees collector, and royalties manager.
- **createOrder**: Creates a new order for an NFT.
- **cancelOrder**: Cancels an existing order.
- **executeOrder**: Executes the sale of an NFT.
- **setFeesCollectorCutPerMillion**: Sets the fee percentage for the marketplace.
- **setRoyaltiesCutPerMillion**: Sets the royalty percentage for the original creators.
- **setFeesCollector**: Sets the address of the fees collector.
- **setRoyaltiesManager**: Sets the address of the royalties manager.

### Deployment Steps

- Deploy the token contract:
```sh
  npx hardhat run ./scripts/token.ts --network ropsten
  npx hardhat verify --network ropsten --contract contracts/NRGY.sol:NRGY 0x4D2C2cd623B4Bfb927f216e5A145aff2F32A51Fd
```
- Deploy the NFT contract:

```sh
npx hardhat run ./scripts/nft.ts --network ropsten
npx hardhat verify --network ropsten --contract contracts/NFT.sol:Axe 0xe41E3886E4f3de8275C2D941Fbc073BF3ec19e9D "AXE" "AXE" "https://p2e.netvrk.co/nfts/"
```
- Deploy the marketplace contract:
```sh
npx hardhat run ./scripts/market.ts --network ropsten
npx hardhat verify --network ropsten --contract contracts/Market.sol:P2EMarketPlace 0x6fb2937aA4b462277FC755685808AEf479dcd8ff "0x4D2C2cd623B4Bfb927f216e5A145aff2F32A51Fd" "0x0Fb90a3C0324A46b7A4BD398bcD99096344339fB" 100
```
- Environment Variables (.env)

```env
ROPSTEN_URL={Ropsten RPC URL}
PRIVATE_KEY={Deployer private key}
ETHERSCAN_API_KEY={Etherscan API for contract verification}
```

### Archived Project
This is an archived project and is no longer used. The code is provided as-is and is not actively maintained. Feel free to explore and learn from the codebase, but please be aware that there may be security vulnerabilities or outdated dependencies.