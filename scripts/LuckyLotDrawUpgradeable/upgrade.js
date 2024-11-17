const { ethers, upgrades } = require("hardhat");

async function main() {
  const LuckyLotDrawV2 = await ethers.getContractFactory(
    "LuckyLotDrawUpgradeableV2"
  );
  console.log("Upgrading LuckyLotDrawUpgradeable...");
  const luckyLotDraw = await upgrades.upgradeProxy(
    "PROXY_CONTRACT_ADDRESS",
    LuckyLotDrawV2
  );
  console.log("LuckyLotDrawUpgradeable upgraded.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
