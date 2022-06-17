import {ethers} from "hardhat";
import {SXPoS} from "../../types/SXPoS";
require("dotenv").config();

const STAKING_CONTRACT_ADDRESS = process.env.STAKING_CONTRACT_ADDRESS ?? '0x0000000000000000000000000000000000001001';

async function main() {
  console.log("Check current contract information");

  const [deployer, val1, val2, val3, val4] = await ethers.getSigners();

  const StakingContractFactory = await ethers.getContractFactory("SXPoS");
  let stakingContract = await StakingContractFactory.attach(STAKING_CONTRACT_ADDRESS) as SXPoS;
  stakingContract = stakingContract.connect(deployer);

  const [stakedAmount, validators, minimumNumValidators, maximumNumValidators, blockReward, epochSize, addressMap] = await Promise.all([
    stakingContract.stakedAmount(),
    stakingContract.callStatic.validators(),
    stakingContract.minimumNumValidators(),
    stakingContract.maximumNumValidators(),
    stakingContract.getBlockReward(),
    stakingContract.getEpochSize(),
    stakingContract._addressToLastBlockReward('0x30b3eCF398eEB21D038Ba6a9221BD40255B4fE04')
  ])

  console.log(`Total staked amount: ${stakedAmount.toString()}`)
  console.log('Minimum number of validators', minimumNumValidators.toNumber());
  console.log('Maximum number of validators', maximumNumValidators.toNumber());
  console.log('Current validators list', validators);
  console.log('Current epoch block reward', blockReward);
  console.log('Current epoch size', epochSize);
  console.log(JSON.stringify(addressMap))

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
