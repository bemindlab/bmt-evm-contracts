import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';
import { parseEther } from 'viem';

describe('AnyoneAirdrop', function () {
  async function deployFixture() {
    const [owner, addr1, addr2] = await hre.viem.getWalletClients();
    const anyoneAirdrop = await hre.viem.deployContract('AnyoneAirdrop', []);
    const publicClient = await hre.viem.getPublicClient();

    // deploy erc20
    const erc20 = await hre.viem.deployContract('ERC20Mock' as string, []);
     // allowance to airdrop
    await erc20.write.approve([anyoneAirdrop.address, '1000000000000000000000']);
    return { owner, addr1, addr2, erc20, anyoneAirdrop, publicClient };
  }

  describe('Deployment', function () {
    it('Should deploy token successfully', async function () {
      const { anyoneAirdrop } = await loadFixture(deployFixture);
      expect(anyoneAirdrop.address).to.not.equal(0);
    });
  });

  describe('Airdrop', function () {
    it('Should airdrop ERC20 successfully', async function () {
      const { owner, addr1, addr2, erc20, anyoneAirdrop, publicClient } = await loadFixture(deployFixture);
      const amount = 1;
      const bigAmount = BigInt(parseEther(amount.toString()));

      // console.log('Owner Balance', owner.account.address, await erc20.read.balanceOf([owner.account.address]));
      // console.log('Addr1 Balance', addr1.account.address, await erc20.read.balanceOf([addr1.account.address]));
      // console.log('Addr2 Balance', addr2.account.address, await erc20.read.balanceOf([addr2.account.address]));
      // console.log('erc20', erc20.address);
      // console.log('anyoneAirdrop', anyoneAirdrop.address);

      await anyoneAirdrop.write.airdropERC20([
        erc20.address,
        [addr1.account.address, addr2.account.address],
        [bigAmount, bigAmount],
      ]);

      expect(await erc20.read.balanceOf([addr1.account.address])).to.equal(bigAmount);
      expect(await erc20.read.balanceOf([addr2.account.address])).to.equal(bigAmount);
    });
  });
});
