const Utils = require("../../Classes/Utils")
const path = require("path")
const ethers = require('ethers')

//bnb testnet
 module.exports = async (network) => {
    return {
        defaultStablecoin: "0x5ea7D6A33D3655F661C298ac8086708148883c34", // busd
        paymentTokens: [
            {   
                tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // bnb
                priceFeedContract: "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526", //bnb-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            },
            {

                tokenAddress: "0xa35062141Fa33BCA92Ce69FeD37D0E8908868AAe", // cake 
                decimals: 18, ///it will be replaced by the right one in contract
                priceFeedContract: "0x81faeDDfeBc2F8Ac524327d70Cf913001732224C", //cake-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            }
        ]
    }
 }

