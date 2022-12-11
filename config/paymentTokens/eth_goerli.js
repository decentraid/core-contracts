const Utils = require("../../classes/Utils")
const path = require("path")
const ethers = require('ethers')

const dexBytes32 = ethers.utils.formatBytes32String("dex")

module.exports = async (network) => {

    //(await getAssetAddress(network, "UsdcToken"));
    let usdcAddress = "0x07865c6e87b9f70255377e024ace6630c1eaa37f" // usdc goerli

    return {
        defaultStablecoin: usdcAddress,
        paymentTokens: [
            {   
                tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", //native token
                priceFeedContract: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",// eth-usd goerli feed
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            },

            {   
                tokenAddress: usdcAddress,
                priceFeedContract: "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7", //usdc-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            }
        ]
    }
    
}

getAssetAddress = async (network, assetName) => {
    
    let assetFilePath = path.resolve(`${__dirname}/../../deployments/${network}/${assetName}.json`)

    let assetContractName = assetName.toUpperCase()

    if(!(await Utils.exists(assetFilePath))){
        Utils.errorMsg(`Asset Deplyment File Not Found at: ${assetFilePath}`)
        throw new Error(`paymentAsset#local.js: Deployment file not found, kindly redeploy ${assetContractName} on ${network}`)
    }

    let dataObj = require(assetFilePath)

    return Promise.resolve(dataObj.address);
}
