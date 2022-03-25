import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { expect } from "chai";
import { Staking } from "../types/Staking";


describe("Staking contract", function () {
  let accounts: SignerWithAddress[];
  let contract: Staking;
  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const MinValidatorCount = 4;
    const MaxValidatorCount = 6;

    const contractFactory = await ethers.getContractFactory("Staking");
    contract = (await contractFactory.deploy(MinValidatorCount, MaxValidatorCount)) as Staking;
    await contract.deployed();
    contract = contract.connect(accounts[0]);
  });

  describe("default", () => {
    it("staked amount should be zero", async () => {
      expect(await contract.stakedAmount()).to.eq(0);
    });

    it("validators should be empty", async () => {
      expect(await contract.validators()).to.be.empty;
    });

    it("isValidator should return false for non-validator", async () => {
      expect(await contract.isValidator(accounts[0].address)).to.be.false;
    });

    it("accountStake should return zero for non-staker", async () => {
      expect(await contract.accountStake(accounts[0].address)).to.equal(0);
    });

    it("minimumNumValidators should be 4", async () => {
      expect(await contract.minimumNumValidators()).to.equal(4);
    });

    it("maximumNumValidators should be 6", async () => {
      expect(await contract.maximumNumValidators()).to.equal(6);
    });
  });

  describe("Stake", () => {
    const value = ethers.utils.parseEther("1");

    const stake = async (account: SignerWithAddress, amount: BigNumber) => {
      return contract.connect(account).stake({ value: amount });
    };

    it("should increase stakedAmount if account send value to contract", async () => {
      await expect(() => contract.stake({ value })).to.changeEtherBalances(
        [accounts[0], contract],
        [value.mul("-1"), value]
      );

      expect(await contract.accountStake(accounts[0].address)).to.equal(value);
    });

    it("should emit Staked event", async () => {
      await expect(contract.stake({ value }))
        .to.emit(contract, "Staked")
        .withArgs(accounts[0].address, value);
    });

    it("should append to validator set if the account has staked enough amount", async () => {
      await contract.stake({ value });

      expect(await contract.validators()).to.include(accounts[0].address);
      expect(await contract.isValidator(accounts[0].address)).to.be.true;
    });

    it("shouldn't append new validator if the account has not staked enough amount", async () => {
      const value = ethers.utils.parseEther("0.5");
      await contract.stake({ value });

      expect(await contract.validators()).not.to.include(accounts[0].address);
      expect(await contract.isValidator(accounts[0].address)).to.be.false;
    });

    it("should reach full validator set capacity", async () => {
      await Promise.all(accounts
          .slice(0, 6)
          .map((account) => {
            stake(account, value);
          })
      );

      await expect(stake(accounts[6], value)).to.be.revertedWith("Validator set has reached full capacity");
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

      expect(await contract.accountStake(account.address)).to.equal(value);
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
      expect(await contract.isValidator(account.address)).to.be.true;
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

    it("should fail to unstake if current validator number equals to the min validator number", async () => {
      // remove 1 account first
      await contract.connect(accounts[1]).unstake();
      // current number of validators should be same to 4 (MinimumRequiredNumValidators)
      await expect(await contract.validators()).to.have.length(4);

      // cannot remove validator anymore
      await expect(contract.unstake()).to.be.revertedWith(
        "Validators can't be less than the minimum required validator num"
      );

      // check the account is still validator
      expect(await contract.isValidator(accounts[0].address)).to.be.true;
      expect(await contract.accountStake(accounts[0].address)).to.equal(
        stakedAmount
      );
    });

    it("should succeed and refund the staked balance", async () => {
      await expect(() => contract.unstake()).to.changeEtherBalances(
        [accounts[0], contract],
        [stakedAmount, stakedAmount.mul("-1")]
      );

      expect(await contract.accountStake(accounts[0].address)).to.equal(0);
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

      expect(await contract.isValidator(accounts[0].address)).to.be.false;
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

    it("should be able to accept a new validator after the last one has unstaked", async () => {
      // Reach full slot capacity
      const value = ethers.utils.parseEther("1");
      await Promise.all(accounts
          .slice(0, 6)
          .map((account) => {
            stake(account, value);
          })
      );

      // Account #0 unstakes
      await contract.connect(accounts[0]).unstake();

      // Account #6 should be able to become a validator
      await expect(stake(accounts[6], value)).not.to.be.revertedWith("Validator set has reached full capacity");
    });
  });
});
