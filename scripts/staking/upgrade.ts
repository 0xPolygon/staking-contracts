import {ethers, upgrades} from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const SXNODE = await ethers.getContractFactory("SXNode");
  const staking = SXNODE.attach(process.env.SXNODE_CONTRACT_ADDRESS!);
  const SXNODEUPGRADES = await ethers.getContractFactory("SXNode");
  const stakingupgraded = await upgrades.upgradeProxy(staking, SXNODEUPGRADES);
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
