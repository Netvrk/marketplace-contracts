## Smart Contracts (Ropsten Network)

- NRGY: 0x946803FAFa7cF519a163802cA44C17DE010E8cF7
- AXE: 0xfe9E31e7E34f8c41456782798d6D0683BA11eBd4
- Market: 0xFDeB0330eBcEA3840518e2E095C1235449DD8117

## Deployment Steps

- npx hardhat run ./scripts/token.ts --network ropsten
- npx hardhat verify --network ropsten --contract contracts/NRGY.sol:NRGY 0x4D2C2cd623B4Bfb927f216e5A145aff2F32A51Fd

- npx hardhat run ./scripts/nft.ts --network ropsten
- npx hardhat verify --network ropsten --contract contracts/NFT.sol:Axe 0xe41E3886E4f3de8275C2D941Fbc073BF3ec19e9D "AXE" "AXE" "https://p2e.netvrk.co/nfts/"

- npx hardhat run ./scripts/market.ts --network ropsten
- npx hardhat verify --network ropsten --contract contracts/Market.sol:P2EMarketPlace 0x6fb2937aA4b462277FC755685808AEf479dcd8ff "0x4D2C2cd623B4Bfb927f216e5A145aff2F32A51Fd" "0x0Fb90a3C0324A46b7A4BD398bcD99096344339fB" 100

## Environment Variables (.env)

- ROPSTEN_URL={Ropsten RPC URL}
- PRIVATE_KEY={Deployer private key}
- ETHERSCAN_API_KEY={Etherscan API for contract verification}
