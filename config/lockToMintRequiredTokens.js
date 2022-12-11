const domainPrices = require("./domainPrices")  

// the lowest required tokens
let _5pchars = 5_000;

// the prices will be parsed to 18 unit 
//using ethers utils.parseUnits by the deployer(processDomainPrices)
//bnb testnet
module.exports = {
    _1char:         getQty("_1char"), //6k usd
    _2chars:        getQty("_2chars"), // 3k usd
    _3chars:        getQty("_3chars"), // 680 usd
    _4chars:        getQty("_4chars"), // 200 usd
    _5pchars:       _5pchars // 25 usd
}

function getQty(key){
    
    //get the price
    let _5pcharsPrice = domainPrices["_5pchars"]

    let _price = domainPrices[key]

    //console.log("_price====>", _price)

    return (_price / _5pcharsPrice) * _5pchars;
}


