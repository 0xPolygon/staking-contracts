const { task } = require("hardhat/config");
const BigNumber = require("ethers").BigNumber;

require("hardhat-deploy");
require("hardhat-deploy-ethers");



const MIN_VALIDATOR_COUNT = process.env.MIN_VALIDATOR_COUNT ?? 1;
const MAX_VALIDATOR_COUNT = process.env.MAX_VALIDATOR_COUNT ?? Number.MAX_SAFE_INTEGER - 1;

const VALIDATOR_REWARD = "100000000000000000";
const STAKING_PROXY_ADDRESS_HAMILTON = "0xF7756997a65b807aDD0231F2e50fe0C272499cb1"
const STAKING_PROXY_ADDRESS_TORONTO = "0xaD556C7D3A458B5c1cfD5575a0B6AE6e3A2A658D";
const STAKING_PROXY_ADDRESS_MAINNET = "";

function getProxyAddress() {
  switch (network.name) {
    case "toronto":
      return STAKING_PROXY_ADDRESS_TORONTO;
    case "mainnet":
      return STAKING_PROXY_ADDRESS_MAINNET;
    default:
      console.error("Invalid network selected");
  }
}

// e.g. npx hardhat staking:deploy --network toronto
task("staking:deploy", "Deploys sx staking contract").setAction(async function () {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // We get the contract to deploy
  const STAKING = await ethers.getContractFactory("SXPoS");
  const staking = await upgrades.deployProxy(STAKING, [BigNumber.from(VALIDATOR_REWARD),MIN_VALIDATOR_COUNT, MAX_VALIDATOR_COUNT], {
    kind: "uups",
    initializer: "initialize",
  });

  console.log("Contract deployed at:", staking.address);
});

// e.g. npx hardhat staking:upgrade --newcontractname STAKING --network toronto
task("staking:upgrade", "Upgrades STAKING contract")
  .addParam("newcontractname", "The new contract name to upgrade to (e.g. STAKING)")
  .setAction(async function ({ newcontractname }) {
    const STAKING = await ethers.getContractFactory("SXPoS");
    const staking = STAKING.attach(getProxyAddress());
    const STAKINGUPGRADED = await ethers.getContractFactory(newcontractname);
    const stakingupgraded = await upgrades.upgradeProxy(staking, STAKINGUPGRADED);
    const version = await stakingupgraded.getVersion();
    console.log("Upgraded contract to version " + version);
  });
