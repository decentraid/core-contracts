
//bnb testnet
module.exports = async (network) => {
    return {
        defaultStableCoin: "0x5ea7D6A33D3655F661C298ac8086708148883c34",
        paymenTokens: [
            {
                tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                priceFeedContract: "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526", //bnb-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            },
            {
                tokenAddress: "0xa35062141Fa33BCA92Ce69FeD37D0E8908868AAe",
                priceFeedContract: "0x81faeDDfeBc2F8Ac524327d70Cf913001732224C", //cake-usd
                enabled: true,
                addedOn: Date.now(),
                updatedOn:  Date.now()
            }
        ]
    }
 }

