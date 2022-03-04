import { ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";

async function main() {
  const accounts = await ethers.getSigners();
  const acceptedToken = "0x4D2C2cd623B4Bfb927f216e5A145aff2F32A51Fd";
  const marketContract: any = await ethers.getContractFactory("P2EMarketPlace");
  const market = await marketContract.deploy(
    acceptedToken,
    accounts[0].address,
    100
  );

  await market.deployed();
  console.log("Market deployed to:", market.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
