import {ethers, upgrades} from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const STAKING = await ethers.getContractFactory("SXPoS");
  const staking = STAKING.attach(process.env.STAKING_CONTRACT_ADDRESS!);
  const STAKINGUPGRADED = await ethers.getContractFactory("SXPoS");
  const stakingupgraded = await upgrades.upgradeProxy(staking, STAKINGUPGRADED);
  const version = await stakingupgraded.getVersion();
  console.log("Upgraded contract to version " + version);

  console.log("Contract address:", staking.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
