import { ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";

async function main() {
  const nftContract = await ethers.getContractFactory("Axe");
  const nft: any = await nftContract.deploy(
    "AXE",
    "AXE",
    "https://p2e.netvrk.co/nfts/"
  );
  await nft.deployed();

  console.log("Axe NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
