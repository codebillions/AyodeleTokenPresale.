const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AyodeleTokenPresale", function () {
  let Token, Presale, token, presale, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    Token = await ethers.getContractFactory("AyodeleToken");
    token = await Token.deploy("Ayodele Token", "AYD", ethers.utils.parseUnits("100000000", 18));
    await token.deployed();

    const now = Math.floor(Date.now() / 1000);
    Presale = await ethers.getContractFactory("AyodeleTokenPresale");
    presale = await Presale.deploy(
      token.address,
      owner.address,
      1000,
      ethers.utils.parseEther("1"),
      ethers.utils.parseEther("10"),
      now - 10,
      now + 3600
    );
    await presale.deployed();

    await token.transferOwnership(presale.address);
  });

  it("should allow whitelisted user to buy tokens", async function () {
    await presale.connect(owner).addToWhitelist(addr1.address);
    const buy = await presale.connect(addr1).buyTokens(addr1.address, { value: ethers.utils.parseEther("1") });
    await buy.wait();

    const balance = await token.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.utils.parseUnits("1000", 18));
  });

  it("should reject non-whitelisted buyer", async function () {
    await expect(
      presale.connect(addr2).buyTokens(addr2.address, { value: ethers.utils.parseEther("1") })
    ).to.be.revertedWith("not whitelisted");
  });
});
