/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

module.exports = class {


     static success(message = "",data = null){
        let option = {
            type: "success",
            message: message,
            data: data 
        }

        return this.processStatus(option)
    }

    static error(message = "",data = null){
        let option = {
            type: "error",
            message: message,
            data: data 
        }
        return this.processStatus(option)
    }

    static info(message = "",data = null){
        let option = {
            type: "info",
            message: message,
            data: data 
        }

        return this.processStatus(option)
    }

    static processStatus(option){

        try{

            let type =  option.type.toLowerCase()
            let message = option.message || ""
            let data = option.data || null 
            let id = option.id || null;

            let statusObj = {
                type:  type,
                message: message,
                data: data,
                id,
                getType:    () => { return type},
                getMessage: () => { return message},
                getData:    () => { return data},
                isError:    () => { return (type == "error")},
                isSuccess:  () => { return (type == "success")},
                isNeutral:  () => { return (type == "neutral")},
                isInfo:     () => { return (type == "info")}
            }

            return statusObj

        } catch(e){
            console.log(option)
            console.log(e,e.stack)
            return this.error(`an error occured ${e.message}`)
        }

    }//end fun 

    static successPromise(message = "",data = null){
        return Promise.resolve(this.success(message,data))
    }

    static errorPromise(message = "",data = null){
        return Promise.resolve(this.error(message,data))
    }

    static infoPromise(message = "",data = null){
        return Promise.resolve(this.info(message,data))
    }

}