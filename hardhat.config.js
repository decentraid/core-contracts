/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

require("@nomiclabs/hardhat-waffle");

require("@nomiclabs/hardhat-ethers");

require("@nomiclabs/hardhat-etherscan");

require('hardhat-contract-sizer');

require('hardhat-deploy');

require('@openzeppelin/hardhat-upgrades');

require('hardhat-abi-exporter',{ path: 'data/abi', clear: true });

const {  
  moralisApiKey,
  accountPrivateKey,
  etherscanAPIKey
} = require(__dirname+'/.secrets.js');


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {

  networks: {

    hardhat: {
      accounts: [{privateKey: `0x${accountPrivateKey}`, balance: "91229544000000000000"}],
      //forking: {
          //url: `https://speedy-nodes-nyc.moralis.io/${moralisApiKey}/bsc/mainnet`
    //  },
    },
    
    bsc_testnet: {
      url:  `https://data-seed-prebsc-2-s3.binance.org:8545/`,
      chainId: 97,
      ///gasPrice: 20000000000,
      accounts: [`0x${accountPrivateKey}`]
    },   
    
    bsc_mainnet: {
      url:  `https://speedy-nodes-nyc.moralis.io/${moralisApiKey}/bsc/mainnet`,
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
    version: "0.8.4",
      settings: {
          optimizer: {
            enabled: true,
            runs: 1
          }
      }
  },

  mocha: {
    timeout: 1000000
  }
};

