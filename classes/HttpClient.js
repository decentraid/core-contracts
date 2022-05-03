/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

const process = require("process")
//const Helpers = require("./Helpers")
const Status = require("./Status")
const axios = require("axios")

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0"

module.exports = class HttpClient {

    static async get(url,data={},headers={}){

        let opts = {
            method: "get",
            url
        }

        if(Object.keys(data).length > 0){
            opts.params = data
        }

        if(Object.keys(headers).length > 0){
            opts.headers = headers
        }        

        let result = this.doRequest(opts)
        
        return Promise.resolve(result)
    }

    static async post(url,data={},headers={}){

        let opts = {
            method: "post",
            url
        }

        if(Object.keys(data).length > 0){
            opts.data = data
        }

        if(Object.keys(headers).length > 0){
            opts.headers = headers
        }        


        let result = this.doRequest(opts)
        
        return Promise.resolve(result)
    }
    


    static async doRequest(opts){
        try{
            
            let response = await axios(opts);

            let data = response.data;

            return Status.successPromise("",data)

        } catch(e){
           
            let response = e.response || {}

           console.log(
                `
                    Axios request error: 
                    Status: ${response.status || ""}
                    URL: ${opts.url}
                    ${console.log(opts)}
                `
            )

            return Status.errorPromise("SYSTEM_BUSY")
        }
    }


    /**
     * getJson
     */
    static async getJSON(url,data={},headers={}){
        try {

            let resultStatus = await  this.get(url, data, headers);

            if(resultStatus.isError()){
                return resultStatus;
            }

            let resultData = resultStatus.getData() 

           // console.log("resultData===>>", resultData)

            if(resultData == null || resultData.length == 0){
                return resultStatus;
            }

            let datatJson = JSON.parse(JSON.stringify(resultData))

            return Status.successPromise("", datatJson);
            
        } catch (e) {
            console.log(`getJSON Error: ${e}`,e)
            return Promise.reject(e)
        }
    } //end fun

    /**
     * jsonRPC
     * @param {*} url 
     * @param {*} rpcMethod 
     * @param {*} params 
     */
    static async jsonRPC(url,rpcMethod,params){

        let data = JSON.stringify({
            "jsonrpc":"2.0",
            "id": Date.now(),
            method: rpcMethod,
            params
        })

        var opts = {
            method: 'post',
            url,
            headers: { 
              'Content-Type': 'application/json'
            },
            data : data
        };
    
        let resultStatus = await this.doRequest(opts)

        if(resultStatus.isError()){
            return Promise.resolve(resultStatus)
        }
        
        let rpcData = resultStatus.getData() || {}

        let error = rpcData.error || null 

        if(error){
            return Promise.resolve(Status.error(error.message || ""))
        }

        let rpcResult = rpcData.result || null;

        return Status.successPromise(null, rpcResult)
    }


}