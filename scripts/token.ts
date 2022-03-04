import { ethers } from "hardhat";

async function main() {
  const nrgyContract = await ethers.getContractFactory("NRGY");
  const nrgy: any = await nrgyContract.deploy();

  await nrgy.deployed();
  console.log("NRGY deployed to:", nrgy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
