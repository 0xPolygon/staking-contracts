import {ethers, upgrades} from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const SXNode = await ethers.getContractFactory("SXNode");
  const sxNode = SXNode.attach(process.env.SXNODE_CONTRACT_ADDRESS!);
  const SXNodeUpgraded = await ethers.getContractFactory("SXNode");
  const sxNodeUpgraded = await upgrades.upgradeProxy(sxNode, SXNodeUpgraded);
  const version = await sxNodeUpgraded.getVersion();
  console.log("Upgraded contract to version " + version);

  console.log("Contract address:", sxNode.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
