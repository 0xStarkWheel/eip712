import { HardhatUserConfig } from "hardhat/types";
import "@shardlabs/starknet-hardhat-plugin";
import "@nomiclabs/hardhat-ethers";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  starknet: {
    // dockerizedVersion: "0.9.0", // alternatively choose one of the two venv options below
    // uses (my-venv) defined by `python -m venv path/to/my-venv`
    venv: "~/cairo_venv",

    // uses the currently active Python environment (hopefully with available Starknet commands!)
    // venv: "active",
    network: "devnet",
    wallets: {
      OpenZeppelin: {
        accountName: "OpenZeppelin",
        modulePath: "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
        accountPath: "~/.starknet_accounts"
      }
    }
  },
  networks: {
    devnet: {
      url: "http://localhost:5050"
    },
    integratedDevnet: {
      url: "http://127.0.0.1:5050/",
    },
    testnet: {
      url: "https://alpha4.starknet.io",
    },
    voyage: {
      url: "http://localhost:8800"
    }
  },
};

export default config;
