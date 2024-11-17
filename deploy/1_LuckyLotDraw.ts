import { ContractFactory, parseEther } from 'ethers';
import hre, { ethers } from 'hardhat';

module.exports = async ({ getNamedAccounts, deployments }: any) => {
  const [deployer] = await ethers.getSigners();
  const { deploy } = deployments;

  const paymentTokenDeployment = await deployments.get('ERC20Mock');
  const paymentToken = paymentTokenDeployment.address;
  const paymentAddress = deployer.address;
  const ticketPrice = parseEther('1');

  // Deploy the implementation contract
  const contractName = 'LuckyLotDraw';
  const contract = await deploy(contractName, {
    contract: contractName,
    from: deployer.address,
    args: [paymentToken, paymentAddress, ticketPrice],
    log: true,
  });

  console.log('Contract Address', contract.address);

  // sleep for 10 seconds to wait for the contract to be deployed
  await new Promise((resolve) => setTimeout(resolve, 10000));

  // Verify the contract
  await hre.run('verify:verify', {
    address: contract.address,
    contract: 'contracts/LuckyLotDraw.sol:LuckyLotDraw',
    constructorArguments: [paymentToken, paymentAddress, ticketPrice],
  });
};

module.exports.tags = ['LuckyLotDraw'];
