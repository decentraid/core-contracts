const Utils = require("../../Classes/Utils")
const path = require("path")

module.exports = async (network) => {

    let usdtAddress = (await getAssetAddress(network, "UsdcToken"));

    return {
        defaultStablecoin: usdtAddress,
        paymentTokens: [
            {
                symbol: "eth",
                tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                priceFeedSource: "dex",
                priceFeedContract: "0x0000000000000000000000000000000000000000", //eth-usd
                dexInfo: {
                    factory: "0x6725F303b657a9451d8BA641348b6761A6CC7a17",
                    router: "0xD99D1c33F9fC3444f8101754aBC46c52416550D1",
                    pricePairToken: "0x0000000000000000000000000000000000000000"
                },
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            },

            {
                symbol: "usdc",
                tokenAddress: usdtAddress,
                priceFeedSource: "dex",
                priceFeedContract: "0x0000000000000000000000000000000000000000", //usdc-usd
                dexInfo: {
                    factory: "0x6725F303b657a9451d8BA641348b6761A6CC7a17",
                    router: "0xD99D1c33F9fC3444f8101754aBC46c52416550D1",
                    pricePairToken: "0x0000000000000000000000000000000000000000"
                },
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
