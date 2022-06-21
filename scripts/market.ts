import "@nomiclabs/hardhat-ethers";
import { ethers, upgrades } from "hardhat";

async function main() {
  const acceptedToken = "0x946803FAFa7cF519a163802cA44C17DE010E8cF7";

  const royaltyManagerContract = await ethers.getContractFactory(
    "RoyaltiesManager"
  );

  const royaltyManager: any = await royaltyManagerContract.deploy();

  await royaltyManager.deployed();
  console.log("RoyaltyManager deployed to:", royaltyManager.address);

  const accounts = await ethers.getSigners();

  const marketContract: any = await ethers.getContractFactory("MarketPlace");
  const market = await upgrades.deployProxy(
    marketContract,
    [
      acceptedToken,
      accounts[0].address,
      2000, // 2%
      royaltyManager.address,
      10000, // 10 %
    ],
    {
      kind: "uups",
    }
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

