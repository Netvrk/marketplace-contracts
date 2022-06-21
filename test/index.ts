import { expect } from "chai";
import { ethers } from "hardhat";

describe("NRGY", function () {
  it("Should deploy NRGY token", async function () {
    const accounts = await ethers.getSigners();
    const nrgyContract = await ethers.getContractFactory("NRGY");
    const nrgy: any = await nrgyContract.deploy();

    await nrgy.deployed();

    const ownerBalance = await nrgy.balanceOf(accounts[0].getAddress());
    expect(ownerBalance).to.equal(await nrgy.totalSupply());
  });
});

