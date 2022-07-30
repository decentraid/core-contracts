const hre = require("hardhat")
const Utils = require("../classes/Utils")
const path = require("path")
const secretsConfig = require("../.secrets.js")
const fsp = require("fs/promises")
const tldsArray = require("../tlds/tlds")

module.exports = async ({getUnnamedAccounts, deployments, ethers, network}) => {

    try{

        let deployedData = {}
        let deployedTLDInfo = {}

        const {deploy} = deployments;
        const [owner, proxyAdmin] = await getUnnamedAccounts();
        let networkName = network.name;
        let chainId = (await ethers.provider.getNetwork()).chainId;

        Utils.successMsg(`ProxyAdmin: ${proxyAdmin}`)
        Utils.successMsg(`owner: ${owner}`)
        Utils.successMsg(`networkName: ${networkName}`)
        Utils.successMsg(`chainId: ${chainId}`)

        /////////////// DEPLOYING PUBLIC RESOLVER & REGISTRAR ////////
        Utils.infoMsg("Deploying TLDS BNS Public Registrar Contract")

        let deployedtRegistrarContract = await deploy('BNS', {
            from: owner,
            log: true,
            proxy: {
                owner: owner,
                proxyContract: "OpenZeppelinTransparentProxy",
                execute: {
                  methodName: "initialize",
                  args: [
                      
                    ]
                }
            }
            
        });

        Utils.successMsg(`Registrar Deloyed: ${deployedtRegistrarContract.address}`);

        deployedData["registrar"] = deployedtRegistrarContract.address;

        ///////// END PUBLIC RESOLVER & REGISTRAR /////////
      
        Utils.infoMsg("Deploying TLDS BNSRegistry Contract")

        for(let tldObj of tldsArray){

            console.log("tldObj====>", tldObj)

            Utils.infoMsg(`Deploying ${tldObj.name} ERC721Registry Contract`)

            let deployedRegistryContract = await deploy('BNSRegistry', {
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
                            tldObj.webHost
                        ]
                    }
                }
                
            });

            let tldContractAddress = deployedRegistryContract.address;

            Utils.successMsg(`TlD ${tldObj.name} Address: ${tldContractAddress}`);

            deployedTLDInfo[tldObj.tldName] = tldContractAddress;
        }

        deployedData["registries"] = deployedTLDInfo;
        ///////////////////////// EXPORT CONTRACT INFO /////////////////////

        
    } catch(e) {
        console.log(e,e.stack)
    }

}