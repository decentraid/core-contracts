const hre = require("hardhat")
const Utils = require("../Utils")
const path = require("path")
const secretsConfig = require("../.secrets.js")
const fsp = require("fs/promises")

module.exports = async ({getUnnamedAccounts, deployments, ethers, network}) => {

    try{
        const {deploy} = deployments;
        const [owner, proxyAdmin] = await getUnnamedAccounts();
        let networkName = network.name;
        let chainId = (await ethers.provider.getNetwork()).chainId;

        Utils.successMsg(`ProxyAdmin: ${proxyAdmin}`)
        Utils.successMsg(`owner: ${owner}`)
        Utils.successMsg(`networkName: ${networkName}`)
        Utils.successMsg(`chainId: ${chainId}`)
        
        

    } catch(e) {
        console.log(e,e.stack)
    }

}