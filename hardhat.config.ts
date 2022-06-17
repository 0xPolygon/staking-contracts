import {HardhatUserConfig} from "hardhat/types";
import "@nomiclabs/hardhat-waffle";
import "tsconfig-paths/register";
import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";


require("dotenv").config();

const privateKeys = (process.env.PRIVATE_KEYS ?? "0000000000000000000000000000000000000000000000000000000000000000").split(",")

const config: HardhatUserConfig = {
  solidity: "0.8.7",
  networks: {
    hardhat: {
      mining: {
        auto: true, // so remaining vesting time actually decreases
        interval: 5000,
      },
      accounts: [
        {
          privateKey: privateKeys[0], // deployer
          balance: "10000000000000000000000",
        },
        {
          privateKey: privateKeys[1], // validator-1
          balance: "10000000000000000000000",
        },
        {
          privateKey: privateKeys[2], // validator-2
          balance: "10000000000000000000000",
        },
        {
          privateKey: privateKeys[3], // validator-3
          balance: "10000000000000000000000",
        },
        {
          privateKey: privateKeys[4], // validator-4
          balance: "10000000000000000000000",
        }
      ],
    },
    toronto: {
      url: "https://rpc.toronto.sx.technology",
      accounts: [...privateKeys],
    },
    mainnet: {
      url: "https://rpc.sx.technology",
      accounts: [...privateKeys],
    },
    polygonedge: {
      url: process.env.JSONRPC_URL ?? "http://localhost:10002",
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
