import {ethers, upgrades} from "hardhat";
import {SXNode} from "../../types/SXNode";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const SXNodeContractFactory = await ethers.getContractFactory("SXNode");
  const sxNode = await upgrades.deployProxy(SXNodeContractFactory, [], 
  {
    kind: "uups",
    initializer: "initialize",
  });

  console.log("SXNode contract address:", sxNode.address);

  const outcomeReporterFactory = await ethers.getContractFactory("OutcomeReporter");
  const outcomeReporter = await upgrades.deployProxy(outcomeReporterFactory, [
    ['0x30b3eCF398eEB21D038Ba6a9221BD40255B4fE04',
      '0xF016C0F8854bcE260261b41150173FB071c9E3F6',
      '0x74615232119ab0eBA508BdBc910FAF7bdD8196d6',
      '0xa24ef1E3C22D2Ab3F20D75f809Fc2D3cf47eF42c'],
      sxNode.address
  ],
  {
    kind: "uups",
    initializer: "initialize",
  })

  console.log("OutcomeReporter contract address:", outcomeReporter.address);

  let sxNodeContract = await SXNodeContractFactory.attach(sxNode.address) as SXNode;
  sxNodeContract = sxNodeContract.connect(deployer);

  const tx = await sxNodeContract.setOutcomeReporter(outcomeReporter.address)

  const receipt = await tx.wait()

  console.log("Finished linking contracts, tx receipt:", receipt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
