import { ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";

async function main() {
  const NRGY = await ethers.getContractFactory("NRGY");
  const nrgy = await NRGY.deploy();

  await nrgy.deployed();

  console.log("NRGY deployed to:", nrgy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
