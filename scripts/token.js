const hre = require("hardhat");

async function main() {
  const NRGToken = await hre.ethers.getContractFactory("NRGToken");
  const nrgy = await NRGToken.deploy();

  await nrgy.deployed();

  console.log("NRGToken deployed to:", nrgy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
