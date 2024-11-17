const { ethers, upgrades } = require("hardhat");

async function main() {
  const LuckyLotDraw = await ethers.getContractFactory(
    "LuckyLotDrawUpgradeable"
  );
  console.log("Deploying LuckyLotDrawUpgradeable...");
  const luckyLotDraw = await upgrades.deployProxy(
    LuckyLotDraw,
    ["TOKEN_ADDRESS", "PAYMENT_ADDRESS", ethers.utils.parseEther("0.01")], // Constructor args
    { initializer: "initialize" }
  );
  await luckyLotDraw.deployed();
  console.log("LuckyLotDrawUpgradeable deployed to:", luckyLotDraw.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
