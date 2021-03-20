import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

import { HardhatUserConfig } from "hardhat/types";

import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ganache";
import "hardhat-typechain";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-web3";
// TODO: reenable solidity-coverage when it works
// import "solidity-coverage";

const INFURA_API_KEY = process.env.INFURA_API_KEY || "a70267ff7dbe4e6aae645a45c4fe9b64";
const RINKEBY_PRIVATE_KEY =
  process.env.RINKEBY_PRIVATE_KEY! ||
  "0093631bce48215deff9f5c1896f5ba3e561ebf14a370af234631011ff1c2b0e"; // well known private key
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const LOCALHOST_PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [{ version: "0.6.8", settings: {} }],
  },
  networks: {
    hardhat: {},
    localhost: {
      url: `http://127.0.0.1:8545`,
      accounts: [LOCALHOST_PRIVATE_KEY],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [RINKEBY_PRIVATE_KEY],
    },
    coverage: {
      url: "http://127.0.0.1:8555", // Coverage launches its own ganache-cli client
    },
    arbitrum: {
      url: "https://kovan3.arbitrum.io/rpc",
      accounts: ["9dd023c504923fd1af261641d29daca91c4139a8d1e51d695d5845d51a8150ee", LOCALHOST_PRIVATE_KEY, RINKEBY_PRIVATE_KEY]
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${INFURA_API_KEY}`,
      accounts: ["9dd023c504923fd1af261641d29daca91c4139a8d1e51d695d5845d51a8150ee", LOCALHOST_PRIVATE_KEY, RINKEBY_PRIVATE_KEY]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
  mocha: {
    timeout: 200000
  }
};

export default config;
