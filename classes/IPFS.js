/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/


const Status = require("./Status")
const { create: IPFSCreate, globSource } = require("ipfs-http-client")
const ipfsConfig = require("../.secrets").ipfsConfig
const Utils = require("./Utils")
const fsp = require("fs/promises")
const path = require("path")
const http = require("./HttpClient")

const ipfs = IPFSCreate(ipfsConfig.nodeConfig)

//console.log("LOL===>>",ipfs.getEndpointConfig())


 module.exports = class IPFS {
    
    static getFileUrl(cid){
        return `${ipfsConfig.gatewayEndpoint}/${cid}`
    }
  
    static async addFileByPath(filePath, filename=null) {
        try {
            
            //lets read the files 
            if(!(Utils.exists(filePath))){
                console.log("IPFS::addFileByPath", "File not found for reading: ", filePath)
                return Status.errorPromise("SYSTEM_BUSY")
            }   

            let fileData = await fsp.readFile(filePath)

            if(!filename){
                filename = path.basename(filePath)
            }

            let file = {path: filename, content: fileData}

            //read file 
            let {cid} = await ipfs.add(file, {
                pin: true   
            })

            cid = cid.toString()
            
            let url = this.getFileUrl(cid)
            
            return Status.successPromise("", { cid, url })

        } catch(e) {
            console.log("IPFS:addFileByPath -> ", filePath)
            console.log(e,e.stack)
            return Status.errorPromise("SYSTEM_BUSY")
        }
    }

    static async addTextContent(textContent, contentFilename=null) {
        try {

            if(contentFilename == null){
                contentFilename = uuidv4()+".txt"
            }

            textContent = textContent.toString();

            let file = {path: contentFilename, content: textContent}

            //lets add to ipfs 
            let {cid} = await ipfs.add(file, {
                 pin: true   
            })

            cid = cid.toString()
            
            let url = this.getFileUrl(cid)

            return Status.successPromise("", { cid, url })

        } catch(e) {
            console.log("IPFS:addTextContent -> ")
            console.log(e,e.stack)
            return Status.errorPromise("SYSTEM_BUSY")
        }
    }


    /**
     * fetch
     */ 
    static async fetch(cid){
        try {

            if(cid.startsWith("ipfs://")){
                cid = cid.replace("ipfs://","")
            }

            let url = `${ipfsConfig.gatewayEndpoint}/${cid}`

            let resStatus = await http.get(url)

            if(resStatus.isError()) return resStatus;

            let resData = resStatus.getData()

            return Status.successPromise("", resData)

        } catch(e) {
            console.log("IPFS:fetch -> ")
            console.log(e,e.stack)
            return Status.errorPromise("SYSTEM_BUSY")
        }
    }

    
    /**
     * unpin, means indirect remove
     */
    static async unpin(cid){
        try {

            if(cid.startsWith("ipfs://")){
                cid = cid.replace("ipfs://","")
            }

           await ipfs.pin.rm(cid)

           return Status.successPromise("UNPIN_SUCCESSFUL")
        } catch(e) {
            console.log("IPFS:unpin -> ")
            console.log(e,e.stack)
            return Status.errorPromise("SYSTEM_BUSY")
        }
    }

 }