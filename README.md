## Smart Contracts

- NRGToken: 0x2f0e662D5F443CFD0B467e7f27049E029e92f8D8

## Deployment Steps

- npx hardhat run ./scripts/token.js --network ropsten
- npx hardhat verify --network ropsten --contract contracts/NRGY.sol:NRGToken 0x2f0e662D5F443CFD0B467e7f27049E029e92f8D8

## Environment Variables (.env)

- ROPSTEN_URL={Ropsten RPC URL}
- PRIVATE_KEY={Deployer private key}
- ETHERSCAN_API_KEY={Etherscan API for contract verification}
