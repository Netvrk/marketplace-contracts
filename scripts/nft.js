const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("Axe");
  const nft = await NFT.deploy();

  await nft.deployed();

  console.log("Axe NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
