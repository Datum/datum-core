pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';


/**
 * @title StorageCostsContract
 * Contract to hold calculate storages and traffic costs
 */
contract StorageCostsContract is Ownable {
    using SafeMath for uint256;

    //value from 8th june 2018
    //1 DAT = $0,022444
    uint256 dollarRate = 22444; //remove leading 0

    //set default costs values in milli cents
    uint costsPerGBData = 500; //values set in cent values
    uint costsPerGBDownoaded = 100; //values set in cent values

    event CoinValueChanged(address sender, uint oldValue, uint newValue);
    event CostsPerGBValueChanged(address sender, uint oldValue, uint newValue);
    event CostsPerGBDownloadedValueChanged(address sender, uint oldValue, uint newValue);

    constructor() public {

    }


    /**
     * @dev Set the actual DAT/USD rate, the value must be provided in 10e6 milli cents, e.g. 1 DAT = $0,022364 --> 22364 micro cents
     * @param value amount of microcents
     */
    function setCoinDollarRate(uint value) onlyOwner public {
        //hold old value for event
        uint256 oldValue = dollarRate;

        //set new value
        dollarRate = value;

        //fire event
        emit CoinValueChanged(msg.sender, oldValue, value);
    }

    /**
     * @dev Set the actual costs for GB stored for 30 days, the value must be provided in cents
     * @param value amount of cents costs for GB stored
     */
    function setCostsPerGBDataStored(uint value) onlyOwner public {
        //hold old value for event
        uint oldValue = costsPerGBData;

        //set new value
        costsPerGBData = value;

        //fire event
        emit CostsPerGBValueChanged(msg.sender, oldValue, value);
    }


    /**
     * @dev Set the actual costs for GB downloaded, the value must be provided in cents
     * @param value amount of cents costs for GB downloaded
     */
    function setCostsPerGBDataDownloaded(uint value) onlyOwner public {
        //hold old value for event
        uint oldValue = costsPerGBDownoaded;

        //set new value
        costsPerGBDownoaded = value;

        //fire event
        emit CostsPerGBDownloadedValueChanged(msg.sender, oldValue, value);
    }


    /**
     * @dev Get actual stored DAT/USD rate in microcents
     */
    function getDollarRate() view public returns (uint) {
        return dollarRate;
    }


    /**
     * @dev Calculate the storage costs for given sizes and duration
     * @param size the size of data that will be stored
     * @param duration how long in days the data should be stored
     */
    function getStorageCosts(uint256 size, uint duration) view public returns (uint) {

        //rounded to 10e9
        uint256 costsInDAT = 5 ether / dollarRate * 1000000;
        uint256 dailyCostsPerGB = costsInDAT.div(30);

        uint GBinBytes = 1024 * 1024 * 1000;

        uint256 costsForStorage = dailyCostsPerGB.mul(duration).div(GBinBytes).mul(size);

        return costsForStorage;
        
    }

    /**
     * @dev Calculate the traffic costs for given sizes and downloads
     * @param size the size of data that will be stored
     * @param downloads amount of downloads estimated
     */
     function getTrafficCosts(uint256 size, uint downloads) view public returns (uint) {
        uint256 costsInDAT = 1 ether / dollarRate * 1000000;

        uint GBinBytes = 1024 * 1024 * 1000;

        uint256 costsForDownloads = costsInDAT.div(GBinBytes).mul(size.mul(downloads));

        return costsForDownloads;
    }

     /**
     * @dev Calculate the traffic costs for given traffic amount
     * @param estimatedGB amount GB of traffic estimated
     */
     function getTrafficCostsGB(uint256 estimatedGB) view public returns (uint) {
        uint256 costsInDAT = 1 ether / dollarRate * 1000000;
        uint256 costsForDownloads = costsInDAT.mul(estimatedGB);
        return costsForDownloads;
    }
}   