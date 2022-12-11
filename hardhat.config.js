/** 
* Blockchain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/
const { alchemyApiKey } = require("./.secrets");

 

require("@nomiclabs/hardhat-waffle");

require("@nomiclabs/hardhat-ethers");

require("@nomiclabs/hardhat-etherscan");

require('hardhat-contract-sizer', { runOnCompile: true });

require('hardhat-deploy');

require('@openzeppelin/hardhat-upgrades');

require('hardhat-abi-exporter',{ path: 'data/abi', clear: true });

const {  
  moralisApiKey,
  accountPrivateKey,
  etherscanAPIKey,
  noderealApiKey
} = require(__dirname+'/.secrets.js');


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {

  networks: {

    hardhat: {
      accounts: [{privateKey: `0x${accountPrivateKey}`, balance: "91229544000000000000"}],
      forking: {
        url: `https://eth-goerli.nodereal.io/v1/${noderealApiKey}`,//`https://eth-goerli.g.alchemy.com/v2/${alchemyApiKey}`,
      },
      chainId: 1337
    },

    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${alchemyApiKey}`,
      chainId: 5,
      ///gasPrice: 20000000000,
      accounts: [`0x${accountPrivateKey}`]
    },   
    
    bsc_testnet: {
      url: `https://data-seed-prebsc-2-s1.binance.org:8545/`,
      chainId: 97,
      ///gasPrice: 20000000000,
      accounts: [`0x${accountPrivateKey}`]
    },   
    
    bsc_mainnet: {
      url:  `https://bsc-dataseed4.binance.org/`,
      chainId: 56,
      ///gasPrice: 20000000000,
      accounts: [`0x${accountPrivateKey}`]
    }

  },

  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: etherscanAPIKey
  },

  solidity: {
    version: "0.8.16",
      settings: {
        viaIR: true,
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
  },

  mocha: {
    timeout: 1000000
  }
};
