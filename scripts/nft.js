const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("Axe");
  const nft1 = await NFT.deploy("Axe1", "AXE1");
  await nft1.deployed();
  console.log("Axe NFT deployed to:", nft1.address);

  const nft2 = await NFT.deploy("Axe2", "AXE2");
  await nft2.deployed();
  console.log("Axe NFT deployed to:", nft2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
