import {ethers} from "hardhat";
import {expect} from "chai";

describe("Staking contract deployment", async () => {
    it("Min validators should not be greater than max validators number", async function () {
        const contractFactory = await ethers.getContractFactory("Staking");
        await expect(contractFactory.deploy(7, 6)).to.be.revertedWith(
            "Min validators num can not be greater than max num of validators"
        );
    })
})