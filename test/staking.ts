import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Staking } from "../types/staking";
import { Deferrable } from "ethers/lib/utils";
import { BigNumber } from "ethers";

describe("Staking contract", function () {
  let accounts: SignerWithAddress[];
  let contract: Staking;
  beforeEach(async () => {
    accounts = await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory("Staking");
    contract = (await contractFactory.deploy()) as Staking;
    await contract.deployed();
    contract = contract.connect(accounts[0]);
  });

  it("staked amount should be default on deployed", async () => {
    expect(await contract.stakedAmount()).to.eq(0);
  });

  describe("Stake", () => {
    const value = ethers.utils.parseEther("1");

    it("should increase stakedAmount if account send value to contract", async () => {
      await expect(() => contract.stake({ value })).to.changeEtherBalances(
        [accounts[0], contract],
        [value.mul("-1"), value]
      );
    });

    it("should emit Staked event", async () => {
      await expect(contract.stake({ value }))
        .to.emit(contract, "Staked")
        .withArgs(accounts[0].address, value);
    });

    it("should append to validator set", async () => {
      await contract.stake({ value });

      expect(await contract.validators()).to.include(accounts[0].address);
    });

    it("shouldn't append new validator", async () => {
      const value = ethers.utils.parseEther("0.5");
      await contract.stake({ value });

      expect(await contract.validators()).not.to.include(accounts[0].address);
    });
  });

  describe("Stake by transfer", () => {
    const value = ethers.utils.parseEther("1");
    let account: SignerWithAddress;

    beforeEach(() => {
      account = accounts[0];
    });

    it("should increase stakedAmount if account send value to contract", async () => {
      await expect(() =>
        account.sendTransaction({
          from: account.address,
          to: contract.address,
          value: value,
        })
      ).to.changeEtherBalances([account, contract], [value.mul("-1"), value]);
    });

    it("should emit Staked event", async () => {
      await expect(
        account.sendTransaction({
          from: account.address,
          to: contract.address,
          value: value,
        })
      )
        .to.emit(contract, "Staked")
        .withArgs(account.address, value);
    });

    it("should append to validator set", async () => {
      await account.sendTransaction({
        from: account.address,
        to: contract.address,
        value: value,
      });

      expect(await contract.validators()).to.include(account.address);
    });
  });

  describe("Unstake", () => {
    const numInitialValidators = 5;
    const stakedAmount = ethers.utils.parseEther("1");
    const stake = async (account: SignerWithAddress, value: BigNumber) => {
      return contract.connect(account).stake({ value });
    };
    beforeEach(async () => {
      // set required number of validators
      await Promise.all(
        accounts
          .slice(0, numInitialValidators)
          .map((account) => stake(account, stakedAmount))
      );
    });

    it("should failed if an account is not a staker", async () => {
      await expect(
        contract.connect(accounts[numInitialValidators]).unstake()
      ).to.be.revertedWith("Only staker can call function");
    });

    it("should failed if current number of validators equals to MinimumRequiredNumValidators", async () => {
      // remove 1 account first
      await contract.connect(accounts[1]).unstake();
      // current number of validators should be same to 4 (MinimumRequiredNumValidators)
      await expect(await contract.validators()).to.have.length(4);

      // cannot remove validator anymore
      await expect(contract.unstake()).to.be.revertedWith(
        "Number of validators can't be less than MinimumRequiredNumValidators"
      );
    });

    it("should succeed and refund the staked balance", async () => {
      await expect(() => contract.unstake()).to.changeEtherBalances(
        [accounts[0], contract],
        [stakedAmount, stakedAmount.mul("-1")]
      );
    });

    it("should succeed and emit Unstaked event", async () => {
      await expect(contract.unstake())
        .to.emit(contract, "Unstaked")
        .withArgs(accounts[0].address, stakedAmount);
    });

    it("should remove account from validators", async () => {
      await contract.unstake();
      expect(await contract.validators())
        .to.have.length(numInitialValidators - 1)
        .not.to.include(accounts[0].address);
    });

    it("should exchange between 2 addresses in validators when contract remove validator in the middle of array", async () => {
      // make sure validators is in order from oldest
      expect(await contract.validators())
        .to.have.length(numInitialValidators)
        .and.to.deep.equal([
          accounts[0].address,
          accounts[1].address,
          accounts[2].address,
          accounts[3].address,
          accounts[4].address,
        ]);

      // first account's unstake
      await contract.unstake();
      expect(await contract.validators())
        // [0, 1, 2, 3, 4] => [4, 1, 2, 3]
        .to.have.length(4)
        .and.to.deep.equal([
          accounts[4].address,
          accounts[1].address,
          accounts[2].address,
          accounts[3].address,
        ]);
    });
  });
});
