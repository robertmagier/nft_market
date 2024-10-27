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
      const { usdt, nft, owner } = await loadFixture(deployNft);
      expect(await nft.USDTTokenAddress()).to.be.equal(await usdt.getAddress());
      expect(await nft.owner()).to.be.equal(owner.address);
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
    });

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

  // Implement unit tests for smart contract buy functionality:

  // Nft Owner should not be able to buy his/her nft.
  // Owner can transfer NFT. In this case price doesn't change.
  // Buy function increases price automatically.
  // Owner can change NFT price.
  // If price is set to 0 then buying is disabled.
  // If buyer didn't approve USDC for our smart contract then buy function should fail.
  // If user doesn't have enough USDC then buy should fail.

  describe('Buy', async function () {
    it('Nft Owner should not be able to his nft', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { nft, owner } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await expect(nft.buy(1)).to.be.revertedWith('You are the owner');
    });

    it('Owner can transfer token to someone else. In this case price doesnt change', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await nft.transfer(otherAccount.address, 1);
      const tokenConfig = await nft.tokenConfig(1);
      expect(tokenConfig.owner).to.be.equal(otherAccount.address);
      expect(tokenConfig.price).to.be.equal(price);
    });

    it('Buy function increases price automatically.', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      const currentNft = nft.connect(otherAccount);
      const expectedCost = await nft.expectedBuyCost(1);

      await usdt.transfer(otherAccount, expectedCost);
      const currentUsdt = usdt.connect(otherAccount);
      await currentUsdt.approve(nft, expectedCost);
      await currentNft.buy(1);
      const tokenConfig = await nft.tokenConfig(1);
      expect(tokenConfig.price).to.be.equal(price * 1.1);
    });

    it('Buy should emit events.', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      const currentNft = nft.connect(otherAccount);

      const expectedCost = await nft.expectedBuyCost(1);
      await usdt.transfer(otherAccount, expectedCost);
      const currentUsdt = usdt.connect(otherAccount);
      await currentUsdt.approve(nft, expectedCost);
      const buyTx = await currentNft.buy(1);
      expect(buyTx).to.emit(nft, 'Transfer');
      await expect(buyTx)
        .to.emit(nft, 'TokenBought')
        .withArgs(1, price, otherAccount.address, owner.address);
    });

    it('Owner can change NFT price.', async function () {
      const uri = 'testURI';
      const price = 1000;
      const newPrice = 2000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await nft.setPrice(1, newPrice);
      const tokenConfig = await nft.tokenConfig(1);
      expect(tokenConfig.price).to.be.equal(newPrice);
    });

    it('Non-owner can not change NFT price.', async function () {
      const uri = 'testURI';
      const price = 1000;
      const newPrice = 2000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await expect(
        nft.connect(otherAccount).setPrice(1, newPrice)
      ).to.be.revertedWith('You are not the owner');
    });

    it('If price is set to 0 then buying is disabled.', async function () {
      const uri = 'testURI';
      const price = 0;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await expect(nft.connect(otherAccount).buy(1)).to.be.revertedWith(
        'Token not for sale'
      );
    });

    it('If buyer didnt approve USDC for our smart contract then buy function should fail.', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await usdt.transfer(otherAccount, 2 * price);
      await expect(nft.connect(otherAccount).buy(1)).to.be.reverted;
    });

    it('If user doesnt have enough USDC then buy should fail.', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await usdt.connect(otherAccount).approve(nft, price);
      await expect(nft.connect(otherAccount).buy(1)).to.be.reverted;
    });
  });

  describe('Fees collection', async function () {
    it('Fees are calculated on top of buying price', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      const currentNft = nft.connect(otherAccount);
      const expectedCost = await nft.expectedBuyCost(1);
      const expectedFee = await nft.expectedFee(1);

      expect(expectedFee).to.be.equal(expectedCost - BigInt(price));
      expect(Number(expectedFee)).to.be.equal(
        (Number(price) * Number(await nft.feePercentage())) / Number(100)
      );
    });
    it('Nft Smart Contract collects fees', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      const currentNft = nft.connect(otherAccount);
      const expectedCost = await nft.expectedBuyCost(1);
      const expectedFee = await nft.expectedFee(1);

      await usdt.transfer(otherAccount, expectedCost);
      const currentUsdt = usdt.connect(otherAccount);
      await currentUsdt.approve(nft, expectedCost);

      await currentNft.buy(1);

      const nftBalance = await usdt.balanceOf(nft);
      expect(nftBalance).to.be.equal(expectedFee);
    });

    it('Smart contract owner can collect fees', async function () {
      const uri = 'testURI';
      const price = 1000;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      const currentNft = nft.connect(otherAccount);
      const expectedCost = await nft.expectedBuyCost(1);
      const expectedFee = await nft.expectedFee(1);

      await usdt.transfer(otherAccount, expectedCost);
      const currentUsdt = usdt.connect(otherAccount);
      await currentUsdt.approve(nft, expectedCost);

      await currentNft.buy(1);

      const ownerBalanceBefore = await usdt.balanceOf(owner);
      await nft.connect(owner).withdrawFees();
      const ownerBalanceAfter = await usdt.balanceOf(owner);

      expect(ownerBalanceAfter - ownerBalanceBefore).to.be.equal(expectedFee);
    });

    it('Smart Contract Owner can change fee %', async function () {
      const uri = 'testURI';
      const price = 1000;
      const newFeePercentage = 20;
      const { owner, otherAccount, nft, usdt } = await loadFixture(deployNft);
      await nft.create(uri, price);
      await nft.setFeePercentage(newFeePercentage);
      const currentNft = nft.connect(otherAccount);
      const expectedCost = await nft.expectedBuyCost(1);
      const expectedFee = await nft.expectedFee(1);

      await usdt.transfer(otherAccount, expectedCost);
      const currentUsdt = usdt.connect(otherAccount);
      await currentUsdt.approve(nft, expectedCost);

      await currentNft.buy(1);

      const nftBalance = await usdt.balanceOf(nft);
      expect(nftBalance).to.be.equal(expectedFee);

      await expect(nft.connect(otherAccount).setFeePercentage(10)).to.be
        .reverted;
    });
  });
});
