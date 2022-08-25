import {ethers, upgrades} from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const OutcomeReporter = await ethers.getContractFactory("OutcomeReporter");
  const outcomeReporter = OutcomeReporter.attach(process.env.OUTCOME_REPORTER_ADDRESS!);
  const OutcomeReporterUpgraded = await ethers.getContractFactory("OutcomeReporter");
  const outcomeReporterUpgraded = await upgrades.upgradeProxy(outcomeReporter, OutcomeReporterUpgraded);
  const version = await outcomeReporterUpgraded.getVersion();
  console.log("Upgraded contract to version " + version);

  console.log("Contract address:", outcomeReporter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
