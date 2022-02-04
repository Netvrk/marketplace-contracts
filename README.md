## Smart Contracts (Ropsten Network)

- NRGY: 0x299b8b0D2A48aC5a5c8dfd971Fc6E619A41Ca6A8
- AXE1: 0x6e28Dd165FAe0baC1a84678a4345Bb4f90D0aD38
- AXE2: 0x881488e75c90B31C4331419dA089c4fFcE5cEc3E

## Deployment Steps

- npx hardhat run ./scripts/token.js --network ropsten
- npx hardhat verify --network ropsten --contract contracts/NRGY.sol:NRGY 0x299b8b0D2A48aC5a5c8dfd971Fc6E619A41Ca6A8
- npx hardhat verify --network ropsten --contract contracts/NFT.sol:Axe 0x6e28Dd165FAe0baC1a84678a4345Bb4f90D0aD38 "Axe1" "AXE1"
- npx hardhat verify --network ropsten --contract contracts/NFT.sol:Axe 0x881488e75c90B31C4331419dA089c4fFcE5cEc3E "Axe2" "AXE2"

## Environment Variables (.env)

- ROPSTEN_URL={Ropsten RPC URL}
- PRIVATE_KEY={Deployer private key}
- ETHERSCAN_API_KEY={Etherscan API for contract verification}
