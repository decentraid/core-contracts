/** 
* Blockchain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
const hre = require("hardhat")
const Utils = require("../classes/Utils")
const path = require("path")
const secretsConfig = require("../.secrets.js")
const fsp = require("fs/promises")
const _lodash = require("lodash")
const defaultDomainPrices = require("../config/domainPrices.js")

const zeroAddress = "0x0000000000000000000000000000000000000000";

module.exports = async ({getUnnamedAccounts, deployments, ethers, network}) => {

    try{

        let deployedData = {}
        let deployedContractsAddresses = {}
        let deployedTLDInfo = {}

        const {deploy} = deployments;
        const [owner, proxyAdmin] = await getUnnamedAccounts();
        let networkName = network.name;
        let chainId = (await ethers.provider.getNetwork()).chainId;

        let signer = await ethers.getSigner(owner)

        //console.log("signer=====>", signer)

        Utils.successMsg(`ProxyAdmin: ${proxyAdmin}`)
        Utils.successMsg(`owner: ${owner}`)
        Utils.successMsg(`networkName: ${networkName}`)
        Utils.successMsg(`chainId: ${chainId}`)
        
        let configFileName = (networkName.startsWith("local")) ? "local" : networkName;

        let TLDsFile = require(`../config/TLDs/${configFileName}.js`)

        let TLDsArrayData = await TLDsFile(networkName)

        await deployMockToken(deploy, networkName, owner)

        let _paymentTokenConfigFile = require(`../config/paymentTokens/${configFileName}.js`)

        let paymentTokenConfig = await _paymentTokenConfigFile(networkName)

        //console.log("paymentTokenConfig===>", paymentTokenConfig)

        /////////////// DEPLOYING PUBLIC RESOLVER & REGISTRAR ////////
        Utils.infoMsg("Deploying TLDS BNS Public Registrar Contract")

        let deployedtRegistrarContract = await deploy('PublicRegistrar', {
            from: owner,
            log: true,
            proxy: {
                owner: owner,
                proxyContract: "OpenZeppelinTransparentProxy",
                execute: {
                  methodName: "initialize",
                  args: [
                        owner, // signer
                        zeroAddress, // treasury address
                        paymentTokenConfig.defaultStablecoin, // default stable coin
                    ]
                }
            }
            
        });

        //console.log("deployedtRegistrarContract=-=======>>>>>", deployedtRegistrarContract)
        

        Utils.successMsg(`Registrar Deloyed: ${deployedtRegistrarContract.address}`);

        deployedContractsAddresses["registrar"] = deployedtRegistrarContract.address;

        ///////// END PUBLIC RESOLVER & REGISTRAR /////////
      
        Utils.infoMsg("Deploying TLDS BNSRegistry Contract")

        //let bnsTLDParamArray = []

        // minters 
        let mintersArray = [owner, deployedtRegistrarContract.address]

        let lastDeployedRegistry;

        for(let tldObj of TLDsArrayData){

            //console.log("tldObj====>", tldObj)

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
                            tldObj.webHost,
                            mintersArray
                        ]
                    }
                }
                
            });

            let tldContractAddress = deployedRegistryContract.address;

            Utils.successMsg(`TlD ${tldObj.name} Address: ${tldContractAddress}`);

            deployedTLDInfo[tldObj.tldName] = tldContractAddress;

            lastDeployedRegistry = deployedRegistryContract;
        }

        deployedContractsAddresses["registries"] = deployedTLDInfo;
        ///////////////////////// EXPORT CONTRACT INFO /////////////////////
        
        ////////////// UPDATE BNS REGISTRAR AND ADD TLD DATA /////

        let addTldMulticallParams = []

        const iface = new ethers.utils.Interface(deployedtRegistrarContract.abi);

        const _domainPrices =  processDomainPrices(ethers, defaultDomainPrices)

        for(let registryName in deployedTLDInfo){

            let registryAddr = deployedTLDInfo[registryName];

            let data = iface.encodeFunctionData("addTLD", [registryName, registryAddr, _domainPrices ]);

            addTldMulticallParams.push(data)
        }

        let registrarContract = new ethers.Contract(
                                deployedtRegistrarContract.address,
                                deployedtRegistrarContract.abi,
                                signer
                            )
        
        Utils.infoMsg("Running addTLD in multicall mode ")
        
        let addTldMulticall = await registrarContract.multicall(addTldMulticallParams)

        Utils.successMsg("addTLD multicall success: "+ addTldMulticall.hash)

        /////////// END //////

        //exporting contract info
        Utils.successMsg("Exporting contract info")

        let contractInfoExportPaths = secretsConfig.contractInfoExportPaths || []

        for(let configDirPath of contractInfoExportPaths){

            //lets create the path 
            await fsp.mkdir(configDirPath, {recursive: true})

            let configFilePath = `${configDirPath}/${chainId}.json`;

            // lets now fetch the data 
            let contractInfoData = {}

            try {
                contractInfoData = require(configFilePath)
            } catch(e){}

            contractInfoData = _lodash.merge({},contractInfoData, deployedContractsAddresses)

            Utils.infoMsg(`New Config For ${networkName} - ${JSON.stringify(contractInfoData, null, 2)}`)

            Utils.successMsg(`Saving ${chainId} contract info to ${configFilePath}`)
            console.log()

            //lets save it back
            await fsp.writeFile(configFilePath, JSON.stringify(contractInfoData, null, 2));
       }



       Utils.successMsg(`Exporting abi files`);

       await hre.run("export-abi");

        // let export the abi
        let abiExportsPathsArray = secretsConfig.abiExportPaths || []

        for(let exportPath of abiExportsPathsArray) {
            
            await fsp.mkdir(exportPath, {recursive: true})
            
            Utils.successMsg(`Exporting registrar.json to ${exportPath}/registrar.json`);
            await fsp.writeFile(`${exportPath}/${chainId}/registrar.json`, JSON.stringify(deployedtRegistrarContract.abi, null, 2));

            if(lastDeployedRegistry != null){
                Utils.successMsg(`Exporting registry.json to ${exportPath}/registry.json`);
                await fsp.writeFile(`${exportPath}/${chainId}/registry.json`, JSON.stringify(lastDeployedRegistry.abi, null, 2));
            }
        }

    } catch(e) {
        console.log(e,e.stack)
    }

}

function processDomainPrices(ethers, domainPricesObj) {
    
    let dataValues = []
    let dataTypes = []

    let bn = ethers.BigNumber;
    let tenExponent = bn.from(10).pow(18)

    for(let key of Object.keys(domainPricesObj)){
        let valueBN = bn.from(domainPricesObj[key].toString()).mul(tenExponent)
        dataValues.push(valueBN)
        dataTypes.push("uint256")
    }

    //let encodedData = ethers.utils.AbiCoder.prototype.encode(dataTypes, dataValues)

    return dataValues;
}


async function deployMockToken (deploy, networkName, owner) {
    if(["hardhat", "local", "localhost"].includes(networkName)){

        isLocalDev = true;
    
        ///////////////////////// USDC Mock Address //////////////
        Utils.infoMsg("Deploying ERC20 USDC Mock Token ");
    
        let deployedUsdcContract = await deploy('UsdcToken', {
            from: owner,
            args: [],
            log:  false
        });
    
        let usdcTokenContractAddress = deployedUsdcContract.address;
    
    
        Utils.successMsg("Deployed ERC20 USDC Mock Token Address: "+ usdcTokenContractAddress);
    
        ///////////////// END USDC MOCK ADDRESS ////////////////////////////
        return { usdc: usdcTokenContractAddress }
    }
}