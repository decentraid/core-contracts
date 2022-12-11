#!/usr/bin/env node

const ethers = require("ethers")
const hre = require("hardhat")
const shelljs = require("shelljs")

const getLastestBlockNo = async  () => {

    console.log("Fetching Latest BlockNumber:")

    //lets check if we have fork url 
    let forkUrl = (hre.config.networks.hardhat || { forking: {} }).forking.url || "";
    
    //(hardhatConfig.networks.hardhat || { forking: {} }).forking.url || "";
    
    if (forkUrl.trim() == "") {
        return ""
    }

    let provider = new ethers.providers.JsonRpcProvider(forkUrl);

    let blockNo = (await provider.getBlockNumber()) - 5;

    console.log("latest blocNumber - 5 blocks back: "+blockNo)
    
    return blockNo
}

const runNode = async () => {
    let latestBlockNo = await getLastestBlockNo()
    shelljs.exec(`npx hardhat node --no-deploy --fork-block-number ${latestBlockNo}`)
}

runNode();