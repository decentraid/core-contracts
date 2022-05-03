/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

const fs = require("fs");
const fsp = require("fs/promises")
const web3Utils = require("web3-utils")
const colors = require("colors");
const _web3 = new (require('web3'))
const BN = require('bn.js');


module.exports = class Utils {

    /**
     * base64Encode
     */
    static  base64Encode(data){
        var buf = Buffer.from(data,'ascii')
        return buf.toString('base64')
    }

    static  base64Decode(data){
        var buf = Buffer.from(data,'base64')
        return buf.toString('ascii')
    }

  /**
   * mkdir
   * @param {*} path 
   */
   static async mkdir(path){

        if(await this.exists(path)){
            return Promise.resolve(true)
        }

        return fsp.mkdir(path,{ recursive: true })
    } //end fun

    /*
    * clearTempFiles
    */
    static async delFile(path){

        if(!(await this.exists(path))){
            return Promise.resolve();
        }

        var err = await fsp.unlink(path)

        if(err){
            return Promise.reject(err)
        }

        return Promise.resolve()
    }//end fun



    static async sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
 
     static exists(path) {
         return (new Promise( (resolve, reject) => {
            fs.access(path, fs.F_OK, (err) => {
                return  resolve((err) ? false : true);
            });  
         }));
     }

    /**
     * parseUnits
     * @param {*} amount 
     * @param {*} decimals 
     * @returns 
     */ 
    static parseUnits(amount, decimals) {
        return ( (BN(amount.toString())).div(BN("10").pow(BN(decimals.toString()))) )
    } 

    static moneyFormat(_str){

        _str = _str.toString()

        let split = _str.split(".")

        let decimals = split[1] || "0"

        let amount = split[0].replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1,");

        return `${amount}.${decimals}`;
     }

    static _toFixed(num, _places = 4) {

        let numFloat = parseFloat(num.toString())
        
        if(numFloat >= 1){
            return numFloat.toFixed(2)
        }

        let parseNo = num.toString().split(".")
        
        let decimalStr = parseNo[1];

        var level = (decimalStr.match(/^0+/) || [''])[0].length

        return numFloat.toFixed(level + _places)
    } 

    static formatMoney(num){
        return this.moneyFormat(this._toFixed(num));
    }

    static async exists(path){
        try{
            
            await fsp.access(path, fs.constants.F_OK | fs.constants.R_OK)

            return Promise.resolve(true)
        } catch(e){
            //console.log(e,e.stack)
            return Promise.resolve(false)
        }
    }
    

    /**
     * isEthAddress
     */
    static isEthAddress(address) {
        return web3Utils.isAddress(address)
    }


    /**
     * fromDaysToMilli
    */
    static fromDaysToMilli(noOfDays) {
        return (60 * 60 * 24 * noOfDays * 1000);
    }

    /**
     * fromMinutesToMilli
     */
     static fromMinutesToMilli(noOfMinutes){
        return (60  * noOfMinutes * 1000);
    }

    /**
     * fromHoursToMilli
     */
    static fromHoursToMilli(noOfHours){
        return (60  * 60 * noOfHours * 1000);
    }


    static successMsg(msg){
        console.log()
        console.log(`==>> %c${colors.bold.green(msg)}`,"font-size: x-large")
    }

    static infoMsg(msg){
        console.log()
        console.log(`==>> %c${colors.bold.blue(msg)}`,"font-size: x-large")
    }


    static errorMsg(msg){
        console.log()
        console.log(`==>> %c${colors.bold.red(msg)}`,"font-size: x-large")
    }


    static web3EncodeParam(dataType, data){
        return  _web3.eth.abi.encodeParameter(dataType,data);
    }

    static numToBytes32(num){
        var bn = new BN(num).toTwos(256);
        return this.padToBytes32(bn.toString(16));
    }


    static padToBytes32(n) {
        while (n.length < 64) {
        n = "0" + n;
        }
        return "0x" + n;
    }

    
    static async sleep(time){
        return (new Promise((resolve, reject) => {
            setTimeout(()=> resolve(true), time)
        }))
    }
    
     static capitalizeFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }
    
 }