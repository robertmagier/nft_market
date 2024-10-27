import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import hre from 'hardhat';

describe('Nft', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNft() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const USDT = await hre.ethers.getContractFactory('DummyUSDT');
    const usdt = await USDT.deploy();

    const Nft = await hre.ethers.getContractFactory('Nft');
    const nft = await Nft.deploy(usdt);

    return { owner, otherAccount, usdt, nft };
  }

  describe('Deployment', function () {
    it('Should set USDT address', async function () {
      const { usdt, nft } = await loadFixture(deployNft);
      expect(await nft.USDTTokenAddress()).to.be.equal(await usdt.getAddress());
    });
  });

  describe('Create', function () {
    it('Anyone should be able to create new NFT', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { otherAccount, nft } = await loadFixture(deployNft);
      let currentNft = nft.connect(otherAccount);
      const createTx = await currentNft.create(uri, price);

      expect(createTx).to.emit(nft, 'Transfer');
      expect(createTx)
        .to.emit(nft, 'TokenCreated')
        .withArgs(1, uri, price, otherAccount.address);

      expect(await nft.balanceOf(otherAccount.address)).to.be.equal(1);
    });

    it('Can set initial price as 0', async function () {
      const uri = 'testURI';
      const price = 0;
      const { otherAccount, nft } = await loadFixture(deployNft);
      let currentNft = nft.connect(otherAccount);
      const createTx = await currentNft.create(uri, price);

      expect(createTx).to.emit(nft, 'Transfer');
      expect(createTx)
        .to.emit(nft, 'TokenCreated')
        .withArgs(1, uri, price, otherAccount.address);

      expect(await nft.balanceOf(otherAccount.address)).to.be.equal(1);
    });

    it('Should fail with empty URI', async function () {
      const uri = '';
      const price = 1000;
      const { otherAccount, nft } = await loadFixture(deployNft);
      let currentNft = nft.connect(otherAccount);
      await expect(currentNft.create(uri, price)).to.be.revertedWith(
        'URI is empty'
      );

      it('token ids should be incremental', async function () {
        const uri = 'testURI';
        const price = 1000;
        const { otherAccount, nft } = await loadFixture(deployNft);
        let currentNft = nft.connect(otherAccount);
        await currentNft.create(uri, price);
        await currentNft.create(uri, price);
        const lastCreateTx = await currentNft.create(uri, price);

        expect(lastCreateTx)
          .to.emit(nft, 'TokenCreated')
          .withArgs(3, uri, price, otherAccount.address);

        expect(await nft.balanceOf(otherAccount.address)).to.be.equal(3);
      });
    });

    //   it('Should set the right owner', async function () {
    //     const { lock, owner } = await loadFixture(deployOneYearLockFixture);

    //     expect(await lock.owner()).to.equal(owner.address);
    //   });

    //   it('Should receive and store the funds to lock', async function () {
    //     const { lock, lockedAmount } = await loadFixture(
    //       deployOneYearLockFixture
    //     );

    //     expect(await hre.ethers.provider.getBalance(lock.target)).to.equal(
    //       lockedAmount
    //     );
    //   });

    //   it('Should fail if the unlockTime is not in the future', async function () {
    //     // We don't use the fixture here because we want a different deployment
    //     const latestTime = await time.latest();
    //     const Lock = await hre.ethers.getContractFactory('Lock');
    //     await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //       'Unlock time should be in the future'
    //     );
    //   });
    // });

    // describe('Withdrawals', function () {
    //   describe('Validations', function () {
    //     it('Should revert with the right error if called too soon', async function () {
    //       const { lock } = await loadFixture(deployOneYearLockFixture);

    //       await expect(lock.withdraw()).to.be.revertedWith(
    //         "You can't withdraw yet"
    //       );
    //     });

    //     it('Should revert with the right error if called from another account', async function () {
    //       const { lock, unlockTime, otherAccount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );

    //       // We can increase the time in Hardhat Network
    //       await time.increaseTo(unlockTime);

    //       // We use lock.connect() to send a transaction from another account
    //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
    //         "You aren't the owner"
    //       );
    //     });

    //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
    //       const { lock, unlockTime } = await loadFixture(
    //         deployOneYearLockFixture
    //       );

    //       // Transactions are sent using the first signer by default
    //       await time.increaseTo(unlockTime);

    //       await expect(lock.withdraw()).not.to.be.reverted;
    //     });
    //   });

    //   describe('Events', function () {
    //     it('Should emit an event on withdrawals', async function () {
    //       const { lock, unlockTime, lockedAmount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );

    //       await time.increaseTo(unlockTime);

    //       await expect(lock.withdraw())
    //         .to.emit(lock, 'Withdrawal')
    //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
    //     });
    //   });

    //   describe('Transfers', function () {
    //     it('Should transfer the funds to the owner', async function () {
    //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
    //         deployOneYearLockFixture
    //       );

    //       await time.increaseTo(unlockTime);

    //       await expect(lock.withdraw()).to.changeEtherBalances(
    //         [owner, lock],
    //         [lockedAmount, -lockedAmount]
    //       );
    //     });
    //   });
  });
});
