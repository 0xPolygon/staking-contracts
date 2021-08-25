import {HardhatUserConfig} from "hardhat/types";
import "@nomiclabs/hardhat-waffle"
import "tsconfig-paths/register";
import "@typechain/hardhat"
import "@nomiclabs/hardhat-ethers"
import "hardhat-gas-reporter"

require("dotenv").config();

const privateKeys = (process.env.PRIVATE_KEYS ?? "").split(",")

const config: HardhatUserConfig = {
  solidity: "0.8.7",
  networks: {
    polygonsdk: {
      url: process.env.POLYGON_SDK_JSONRPC_URL ?? "http://localhost:10002",
      accounts: [
        ...privateKeys,
      ],
    },
  },
  gasReporter: {
    currency: "EUR",
    gasPrice: 21
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
    alwaysGenerateOverloads: false,
    externalArtifacts: ["externalArtifacts/*.json"],
  },
};

export default config;
