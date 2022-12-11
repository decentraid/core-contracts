const Utils = require("../../Classes/Utils")
const path = require("path")
const ethers = require('ethers')

//bnb testnet
 module.exports = async (network) => {
    return {
       // defaultStablecoin: "0x5ea7D6A33D3655F661C298ac8086708148883c34", // busd
        paymentTokens: [
            {   
                tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", // bnb
                priceFeedContract: "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526", //bnb-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            },
            {
                tokenAddress: "0x60cD0522c91916d1633bc025aF341d23FAe5bd40", // our own usdc (usdcToken)
                priceFeedContract: "0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa", //busd-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            }
        ]
    }
 }

