const hre = require("hardhat")
const Utils = require("../classes/Utils")
const path = require("path")
const secretsConfig = require("../.secrets.js")
const fsp = require("fs/promises")
const tldsArray = require("../tlds/tlds")

module.exports = async ({getUnnamedAccounts, deployments, ethers, network}) => {

    try{

        let deployedTLDInfo = {}

        const {deploy} = deployments;
        const [owner, proxyAdmin] = await getUnnamedAccounts();
        let networkName = network.name;
        let chainId = (await ethers.provider.getNetwork()).chainId;

        Utils.successMsg(`ProxyAdmin: ${proxyAdmin}`)
        Utils.successMsg(`owner: ${owner}`)
        Utils.successMsg(`networkName: ${networkName}`)
        Utils.successMsg(`chainId: ${chainId}`)
        
      
        Utils.infoMsg("Deploying TLDS ERC721Registry Contract")

        for(let tldObj of tldsArray){

            console.log("tldObj====>", tldObj)

            Utils.infoMsg(`Deploying ${tldObj.name} ERC721Registry Contract`)

            let deployedRegistryContract = await deploy('ERC721Registry', {
                from: owner,
                log: true,
        
                proxy: {
                    owner: owner,
                    proxyContract: "OpenZeppelinTransparentProxy",
                    execute: {
                      methodName: "initialize",
                      args: [
                            tldObj.name,
                            tldObj.symbol,
                            tldObj.tldName,
                            tldObj.webHost,
                            tldObj.hasExpiry
                        ]
                    }
                }
                
            });

            let tldContractAddress = deployedRegistryContract.address;

            Utils.successMsg(`TlD ${tldObj.name} Address: ${tldContractAddress}`);

            deployedTLDInfo[tldObj.tldName] = tldContractAddress;
        }

        ///////////////////////// EXPORT CONTRACT INFO /////////////////////


    } catch(e) {
        console.log(e,e.stack)
    }

}