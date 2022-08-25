import {ethers} from "hardhat";
import {OutcomeReporter} from "../../types/OutcomeReporter";
require("dotenv").config();

async function main() {
  console.log("Check current contract information");

  const [deployer] = await ethers.getSigners();

  const OutcomeReporterFactory = await ethers.getContractFactory("OutcomeReporter");
  let outcomeReporter = await OutcomeReporterFactory.attach(process.env.OUTCOME_REPORTER_CONTRACT_ADDRESS!) as OutcomeReporter;
  outcomeReporter = outcomeReporter.connect(deployer);

  const validators = await outcomeReporter.getValidators()
  console.log('validators: ', validators)
  const lastReporter = await outcomeReporter.lastReporter()
  console.log('last reporter: ', lastReporter)
  const marketHash = await outcomeReporter.lastMarketHash()
  console.log('last marketHash: ', marketHash)
  const reportedOutcome = await outcomeReporter.reportedOutcome()
  console.log('last reportedOutcome: ', reportedOutcome)
  const hashedReport = await outcomeReporter.hashedReport()
  console.log('last hashedReport: ', hashedReport)
  const signer = await outcomeReporter.getSigner()
  console.log('1st signer: ', signer)
  const sigBytes = await outcomeReporter.sigBytes()
  console.log('1st sigBytes: ', sigBytes)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
