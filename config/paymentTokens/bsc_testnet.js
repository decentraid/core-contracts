
//bnb testnet
 module.exports = async (network) => {
    return {
        defaultStableCoin: "0x5ea7D6A33D3655F661C298ac8086708148883c34",
        paymenTokens: [
            {
                symbol: "bnb",
                tokenAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                priceFeedSource: "chainlink",
                priceFeedContract: "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526", //bnb-usd
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
                symbol: "cake",
                tokenAddress: "0xa35062141Fa33BCA92Ce69FeD37D0E8908868AAe",
                priceFeedSource: "chainlink",
                priceFeedContract: "0x81faeDDfeBc2F8Ac524327d70Cf913001732224C", //cake-usd
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

