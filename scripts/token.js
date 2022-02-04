const hre = require("hardhat");

async function main() {
  const NRGY = await hre.ethers.getContractFactory("NRGY");
  const nrgy = await NRGY.deploy();

  await nrgy.deployed();

  console.log("NRGY deployed to:", nrgy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
