import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';
import { Account } from 'viem';

describe('LuckyLotDraw', function () {
  async function deployFixture() {
    const [owner] = await hre.viem.getWalletClients();
    const erc20 = await hre.viem.deployContract('ERC20Mock' as string, []);
    const luckyLotDraw = await hre.viem.deployContract('LuckyLotDraw' as string, [
      erc20.address,
      owner.account.address,
      '1000000000000000000000',
    ]);
    const publicClient = await hre.viem.getPublicClient();
    return { owner, erc20, luckyLotDraw, publicClient };
  }

  describe('Deployment', function () {
    it('Should deploy token successfully', async function () {
      const { erc20 } = await loadFixture(deployFixture);
      expect(erc20.address).to.not.equal(0);
    });

    it('Should deploy lucky lot draw successfully', async function () {
      const { luckyLotDraw } = await loadFixture(deployFixture);
      expect(luckyLotDraw.address).to.not.equal(0);
    });
  });

  describe('LuckyLotDraw', function () {
    it('Should enter successfully', async function () {
      const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
      const ticketNumber = 1;
      await erc20.write.approve([luckyLotDraw.address, '1000000000000000000000'], { from: owner.account });
      expect(await luckyLotDraw.write.enter([ticketNumber], { from: owner.account })).to.not.throw;
    });

    it('Should clsose round successfully', async function () {
      const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
      expect(await luckyLotDraw.write.closeRound([], { from: owner.account })).to.not.throw;
    });

    // it('Should draw winner successfully', async function () {
    //   const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
    //   expect(await luckyLotDraw.write.setWinningNumber([], { from: owner.account })).to.not.throw;
    // });

    it('Should withdraw successfully', async function () {
      const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
      erc20.write.transfer([luckyLotDraw.address, '1000000000000000000000'], { from: owner.account });
      expect(await luckyLotDraw.write.withdraw([erc20.address])).to.not.throw;
    });

    it('Should all enter and closed round successfully', async function () {
      const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
      await erc20.write.approve([luckyLotDraw.address, '1000000000000000000000000'], { from: owner.account });
      //enter the round 0-99
      for (let i = 0; i < 100; i++) {
        await luckyLotDraw.write.enter([i], { from: owner.account });
      }

      const [round, isClosed] = (await luckyLotDraw.read.rounds([1])) as [number, boolean];
      expect(isClosed).to.be.true;
    });

    it('Should refund successfully', async function () {
      const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
      await erc20.write.approve([luckyLotDraw.address, '1000000000000000000000000'], { from: owner.account });
      //enter the round 0-99
      for (let i = 0; i < 10; i++) {
        await luckyLotDraw.write.enter([i], { from: owner.account });
      }
      expect(await luckyLotDraw.write.refundAll([1], { from: owner.account })).to.not.throw;
    });

    it('Should set winning number successfully', async function () {
      const { owner, erc20, luckyLotDraw } = await loadFixture(deployFixture);
      await erc20.write.approve([luckyLotDraw.address, '1000000000000000000000000'], { from: owner.account });

      //enter the round 0-99
      for (let i = 0; i < 100; i++) {
        await luckyLotDraw.write.enter([i], { from: owner.account });
      }

      expect(await luckyLotDraw.write.setWinningNumber([1], { from: owner.account })).to.not.throw;
      expect(((await luckyLotDraw.read.rounds([1])) as [number, boolean, number])[2]).to.not.equal(0);
    });
  });
});
