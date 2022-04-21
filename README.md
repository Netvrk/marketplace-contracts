## Smart Contracts (Ropsten Network)

- NRGY: 0x12381D72b130376a00C73658755ea621071787D6
- AXE: 0x89B79022c5e0E2EACC21ef5b37AB50D5a98389A3
- Market: 0x0bf3a41811Cd332D7D56b036Ab7a5251Af8A478B

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
