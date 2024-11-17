import hre, { ethers } from 'hardhat';

module.exports = async ({ getNamedAccounts, deployments }: any) => {
    const [deployer] = await ethers.getSigners();
    const { deploy } = deployments;

    // Deploy the implementation contract
    const contractName = 'ERC20Mock';
    const contract = await deploy(contractName, {
        contract: contractName,
        from: deployer.address,
        args: [],
        log: true,
    });

    console.log('Contract Address', contract.address);

    // sleep for 10 seconds to wait for the contract to be deployed
    await new Promise((resolve) => setTimeout(resolve, 10000));

    // Verify the contract
    await hre.run('verify:verify', {
        address: contract.address,
        contract: 'contracts/LuckyLotDraw.sol:ERC20Mock',
        constructorArguments: [deployer.address],
    });

};

module.exports.tags = ['ERC20Mock'];
