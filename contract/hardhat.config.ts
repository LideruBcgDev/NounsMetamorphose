import "dotenv/config";
import "@nomiclabs/hardhat-waffle";
import type { HardhatUserConfig } from "hardhat/config";
require("./scripts/tasks");
import { getEnvVariable } from "./scripts/helpers";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-etherscan";


const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  solidity: "0.8.9",
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      bsc: process.env["BSCSCAN_API"]!,
      bscTestnet:process.env["BSCSCAN_API"]!,
      polygon:process.env["POLYGON_API"]!,
      polygonMumbai: process.env["POLYGON_API"]!,
      mainnet:process.env["ETH_API"]!,
      rinkeby: process.env["ETH_API"]!
    }
  },
  networks: {
    localhost: {
      url: "http://localhost:8545",
      chainId: 31337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
      },
    },
    kovan: {
      url: "https://kovan.optimism.io/",
      chainId: 69,
      accounts: [getEnvVariable("ACCOUNT_PRIVATE_KEY")],
    },
    ethereum: {
      url: getEnvVariable("MAINNET_RPC"),
      chainId: 1,
      accounts: [getEnvVariable("ACCOUNT_PRIVATE_KEY")],
    },
    rinkeby: {
      url: getEnvVariable("RINKEBY_RPC"),
      chainId: 4,
      accounts: [getEnvVariable("ACCOUNT_PRIVATE_KEY")],
    },
    astar: {
      url: "https://rpc.astar.network:8545",
      chainId: 592,
      accounts: [getEnvVariable("ACCOUNT_PRIVATE_KEY")],
    },
    shibuya: {
      url: "https://rpc.shibuya.astar.network:8545",
      chainId: 81,
      accounts: [getEnvVariable("ACCOUNT_PRIVATE_KEY")],
    },
  },
};

export default config;
