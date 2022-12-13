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
///const lockToMintRequiredTokensData = require("../config/lockToMintRequiredTokens")
const lockToMintTokenAddresses = require("../config/lockToMintTokenAddresses.js")
const { lockToMintMinimumRequiredTokens } = require("../config/GeneralConfig")


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

        // deploy local tokens needed for payment tokens
        if (["localhost", "local", "hardhat"].includes(networkName)) {

            Utils.infoMsg("Deploying UsdcToken Contract")

            //first deploy usdc
            let usdcToken = await deploy('UsdcToken', {
                from: owner,
                log: true
            });

            Utils.infoMsg(`UsdcToken: ${usdcToken.address}`)
        }
        
        let configFileName = (networkName.startsWith("local")) ? "local" : networkName;

        let TLDsFile = require(`../config/TLDs/${configFileName}.js`)

        let TLDsArrayData = await TLDsFile(networkName)

        let _paymentTokenConfigFile = require(`../config/paymentTokens/${configFileName}.js`)

        let paymentTokenConfig = await _paymentTokenConfigFile(networkName)

        let lockToMintTokenAddress;

        if (["localhost", "local", "hardhat"].includes(networkName)) {

            lockToMintTokenAddress = await deployMockToken({
                deploy,
                networkName,
                owner,
                tokenName: "Decentraid",
                tokenSymbol: "DID"
            })
        } else {

            lockToMintTokenAddress = lockToMintTokenAddresses[networkName] || ""

            if(lockToMintTokenAddress == "" || lockToMintTokenAddress == zeroAddress) {
                throw new Error(`lockToMintTokenAddress address is missing for network ${networkName}`)
            }
        }
        
        deployedContractsAddresses["projectToken"] = lockToMintTokenAddress;

        //console.log("deployedContractsAddresses====>>>>", deployedContractsAddresses)

        //return false;

        ///////////// START DEPLOY OF NAME LABEL VALIDATOR ///////////////////
        Utils.infoMsg("Deploying MetadataGenerator Contract")

        let deployedMetadataGen = await deploy('MetadataGen', {
            from: owner,
            log: true
        });

        Utils.successMsg(`deployedMetadataGen Deloyed: ${deployedMetadataGen.address}`);

        deployedContractsAddresses["metadataGen"] = deployedMetadataGen.address;
        ///////////////// END DEPLOY NAME LABEL VALIDATOR ////////////////


        ///////////// START DEPLOY OF NAME LABEL VALIDATOR ///////////////////
        Utils.infoMsg("Deploying NameLabelValidator Contract")

        let deployedNameLabelValidator = await deploy('LabelValidator', {
            from: owner,
            log: true
        });

        Utils.successMsg(`NameLabelValidator Deloyed: ${deployedNameLabelValidator.address}`);

        // dont include it
        ///deployedContractsAddresses["nameLabelValidator"] = deployedNameLabelValidator.address;
        ///////////////// END DEPLOY NAME LABEL VALIDATOR ////////////////


        //console.log("paymentTokenConfig===>", paymentTokenConfig)

        /////////////// DEPLOYING PUBLIC RESOLVER & REGISTRAR ////////
        Utils.infoMsg("Deploying Public Registrar Contract")

        let deployedRegistrarContract = await deploy('Registrar', {
            from: owner,
            log: true,
            proxy: {
                owner: owner,
                proxyContract: "OpenZeppelinTransparentProxy",
                execute: {
                  methodName: "initialize",
                    args: [
                        zeroAddress, // initial Registry Addr
                        owner, // signer
                        zeroAddress, // treasury address
                        deployedNameLabelValidator.address,
                        lockToMintTokenAddress
                    ]
                }
            }
            
        });

        //console.log("deployedtRegistrarContract=-=======>>>>>", deployedtRegistrarContract)
        

        Utils.successMsg(`Registrar Deloyed: ${deployedRegistrarContract.address}`);

        deployedContractsAddresses["registrar"] = deployedRegistrarContract.address;


        let registrarContract = new ethers.Contract(
                                deployedRegistrarContract.address,
                                deployedRegistrarContract.abi,
                                signer
        )

        const registrarIface = new ethers.utils.Interface(deployedRegistrarContract.abi);
         
        const pTokensMulticallParams = []
        
        let paymentTokensArray = paymentTokenConfig.paymentTokens

        for( let pTokenInfo of  paymentTokensArray){

            let data = registrarIface.encodeFunctionData("addPaymentToken", [pTokenInfo]);

            pTokensMulticallParams.push(data)
        }

        
        //////// Add Payment Tokens /////////////

        /*/ the lock to mint required tokens is formated similar to domain prices
        const _lockToMintRequiredTokens = processDomainPrices(ethers, lockToMintRequiredTokensData)

        pTokensMulticallParams.push(
            registrarIface.encodeFunctionData("setLockToMintRequiredTokens", [_lockToMintRequiredTokens])
        );*/
        
        if (lockToMintMinimumRequiredTokens > 0) {
            pTokensMulticallParams.push(
                registrarIface.encodeFunctionData(
                    "setLockToMintMinimumRequiredTokens",
                    [lockToMintMinimumRequiredTokens]
                )
            );
        }

        Utils.infoMsg("Running addPaymentToken & setLockToMintRequiredTokens in multicall mode ")
        
        let registrarMulticall = await registrarContract.multicall(pTokensMulticallParams)

        //lets wait for tx to complete 
        await registrarMulticall.wait();

        Utils.successMsg("Registrar multicall success: "+ registrarMulticall.hash)

        ///////// END  REGISTRAR /////////
      
        Utils.infoMsg("Deploying TLDS Registry Contract Files")

        //let bnsTLDParamArray = []

        // minters 
        let mintersArray = [owner, deployedRegistrarContract.address]


        let deployedRegistryContract = await deploy('Registry', {

            from: owner,
            log: true,

            proxy: {
                owner: owner,
                proxyContract: "OpenZeppelinTransparentProxy",
                execute: {
                methodName: "initialize",
                args: [
                       "Decentra NFT Identities",
                       "DID",
                        mintersArray,
                        deployedMetadataGen.address,
                        deployedNameLabelValidator.address
                    ]
                }
            }
            
        });

        let registryAddress = deployedRegistryContract.address;

        Utils.successMsg(`Registry Address: ${registryAddress}`);
    
        deployedContractsAddresses["registry"] = registryAddress;

        let registryContract = new ethers.Contract(
                        registryAddress,
                        deployedRegistryContract.abi,
                        signer
        )

        ///////////////////////// EXPORT CONTRACT INFO /////////////////////
        
        ////////////// UPDATE BNS REGISTRAR AND ADD TLD DATA /////

        /// lets set the registry address in the registrar
        Utils.infoMsg("Setting Resgitry Address in Registar Contract")

        let registarSetRegistryAddr = await registrarContract.setRegistry(registryAddress)

        Utils.successMsg(`registrarSetRegitryAddr success: ${registarSetRegistryAddr.hash}`);

        let addTldMulticallParams = []

        const registryIface = new ethers.utils.Interface(deployedRegistryContract.abi);

        const _domainPrices = processDomainPrices(ethers, defaultDomainPrices);
        
        let tldType = ethers.utils.solidityKeccak256(["string"], ["TLD_TYPE_DOMAIN"]);
        
        let tldsToChainMap = {}

        for(let tldObj of TLDsArrayData){

            if(!tldObj.tld) continue;
            
            let params = [   
                tldObj.tld,
                tldType, // tld type
                tldObj.webHost,
                "", //metadata uri
                3, //minLength
                0, // maxLength
                _domainPrices
            ]

            //console.log("params===>", params)

            let data = registryIface.encodeFunctionData("addTLD",params);

            addTldMulticallParams.push(data)

            tldsToChainMap[tldObj.tld] = chainId;
        }

      
        Utils.infoMsg("Running addTLD in multicall mode ")
        
        let addTldMulticall = await registryContract.multicall(addTldMulticallParams)

        await addTldMulticall.wait()

        Utils.successMsg("addTLD multicall success: "+ addTldMulticall.hash)

        /////////// END //////

        /// lets deploy resolver

        Utils.infoMsg("Deploying the resolver")

        let deployedResolverContract = await deploy('Resolver', {
            
            from: owner,
            log: true,
            proxy: {
                owner: owner,
                proxyContract: "OpenZeppelinTransparentProxy",
                execute: {
                methodName: "initialize",
                    args: [deployedRegistryContract.address]
                }
            }
            
        });

        Utils.successMsg("resolver deployed successfully: " + deployedResolverContract.hash)

        deployedContractsAddresses["resolver"] = deployedResolverContract.address;

        //setting resolver to registry
        Utils.infoMsg("Setting Registry Resolver")
        
        let setRegistryResolver = await registryContract.setResolver(deployedResolverContract.address)

        Utils.successMsg("set registry's resolver success: "+ setRegistryResolver.hash)

        Utils.infoMsg("Deploying ZMulticall contract")

        let deployedZMulticall = await deploy('ZMultiCall', {
            from: owner,
            log: true
        });

        Utils.successMsg(`ZMulticall deployed successfully: ${deployedZMulticall.address}`)

        deployedContractsAddresses["multicall"] = deployedZMulticall.address;
        
        //exporting contract info
        Utils.infoMsg("Exporting contract info")

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

        
       Utils.successMsg("Exporting tlds  info")

       let tldsExportPaths = secretsConfig.tldsExportPaths || []
       
       for(let tldInfoFile of tldsExportPaths){
       
           await fsp.mkdir(path.dirname(tldInfoFile), {recursive: true})
       
           let tldsData = {}
       
           try { tldsData = require(tldInfoFile) } catch(e){ }
       
           tldsData = _lodash.merge({},tldsData, tldsToChainMap)
       
           //lets save it back
           await fsp.writeFile(tldInfoFile, JSON.stringify(tldsData, null, 2));
       }


       Utils.successMsg(`Exporting abi files`);

       await hre.run("export-abi");

        // let export the abi
        let abiExportsPathsArray = secretsConfig.abiExportPaths || []

        for(let exportPath of abiExportsPathsArray) {

            let exportDir = `${exportPath}/`
            
            await fsp.mkdir(exportDir, {recursive: true})
            
            Utils.successMsg(`Exporting registrar.json to ${exportPath}/registrar.json`);
            await fsp.writeFile(`${exportDir}/registrar.json`, JSON.stringify(deployedRegistrarContract.abi, null, 2));

            Utils.successMsg(`Exporting metadataGen.json to ${exportPath}/metadataGen.json`);
            await fsp.writeFile(`${exportDir}/metadataGen.json`, JSON.stringify(deployedMetadataGen.abi, null, 2));

            
            Utils.successMsg(`Exporting resolver.json to ${exportPath}/resolver.json`);
            await fsp.writeFile(`${exportDir}/resolver.json`, JSON.stringify(deployedResolverContract.abi, null, 2));


            Utils.successMsg(`Exporting registry.json to ${exportPath}/registry.json`);
            await fsp.writeFile(`${exportDir}/registry.json`, JSON.stringify(deployedRegistryContract.abi, null, 2));
        
            Utils.successMsg(`Exporting multicall.json to ${exportPath}/multicall.json`);
            await fsp.writeFile(`${exportDir}/multicall.json`, JSON.stringify(deployedZMulticall.abi, null, 2));
        
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


async function deployMockToken ({ deploy, networkName, owner, tokenName, tokenSymbol }) {
    //if(["hardhat", "local", "localhost"].includes(networkName)){

        isLocalDev = true;
    
        ///////////////////////// USDC Mock Address //////////////
        Utils.infoMsg("Deploying ERC20 USDC Mock Token ");
    
        let deployedContract = await deploy('ERC20MockToken', {
            from: owner,
            args: [tokenName, tokenSymbol],
            log:  false
        });
    
    
        Utils.successMsg(`Deployed ERC20 Mock Token Address ${tokenName} (${tokenSymbol}): `+ deployedContract.address);
    
        ///////////////// END USDC MOCK ADDRESS ////////////////////////////
        return deployedContract.address;
    //}
}