const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  const name = "Ayodele Token";
  const symbol = "AYD";
  const cap = hre.ethers.utils.parseUnits("100000000", 18);

  const Token = await hre.ethers.getContractFactory("AyodeleToken");
  const token = await Token.deploy(name, symbol, cap);
  await token.deployed();
  console.log("Token deployed to:", token.address);

  const wallet = deployer.address;
  const rate = 1000;
  const softCap = hre.ethers.utils.parseEther("10");
  const hardCap = hre.ethers.utils.parseEther("50");
  const now = Math.floor(Date.now() / 1000);
  const openingTime = now + 60;
  const closingTime = now + 60 * 60 * 24 * 7;

  const Presale = await hre.ethers.getContractFactory("AyodeleTokenPresale");
  const presale = await Presale.deploy(token.address, wallet, rate, softCap, hardCap, openingTime, closingTime);
  await presale.deployed();
  console.log("Presale deployed to:", presale.address);

  const tx = await token.transferOwnership(presale.address);
  await tx.wait();
  console.log("Token ownership transferred to presale:", presale.address);

  console.log("Deployment complete.");
}

main().then(() => process.exit(0)).catch((error) => {console.error(error);process.exit(1);});
