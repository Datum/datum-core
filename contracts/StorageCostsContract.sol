pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Administratable.sol';


/**
 * @title StorageCostsContract
 * Contract to hold calculate storages and traffic costs
 */
contract StorageCostsContract is Administratable {
    using SafeMath for uint256;

    //value from 8th june 2018
    //1 DAT = $0,000776
    uint dollarRate = 776; //remove leading 0 and hold as 10e6

    //set default costs in DAT/ETH
    uint costsPerGBData = 5 ether; //values set in cent values
    uint costsPerGBDownloaded = 100 ether; //values set in cent values

    event CoinValueChanged(address sender, uint oldValue, uint newValue);
    event CostsPerGBValueChanged(address sender, uint oldValue, uint newValue);
    event CostsPerGBDownloadedValueChanged(address sender, uint oldValue, uint newValue);

    constructor() public {
    }

    /**
     * @dev Set the actual DAT/USD rate, the value must be provided in 10e6 milli cents, e.g. 1 DAT = $0,022364 --> 22364 micro cents
     * @param value amount of microcents
     */
    function setCoinDollarRate(uint value) onlyAdmins public {
        //hold old value for event
        uint256 oldValue = dollarRate;

        //set new value
        dollarRate = value;

        //fire event
        emit CoinValueChanged(msg.sender, oldValue, value);
    }

    /**
     * @dev Set the actual costs for GB stored for 30 days, the value must be as DAT in (wei), e.g. 5 DAT --> 5000000000000000000
     * @param value amount of cents costs for GB stored
     */
    function setCostsPerGBDataStored(uint value) onlyAdmins public {
        //hold old value for event
        uint oldValue = costsPerGBData;

        //set new value
        costsPerGBData = value;

        //fire event
        emit CostsPerGBValueChanged(msg.sender, oldValue, value);
    }


    /**
     * @dev Set the actual costs for GB downloaded, the value must be provided as DAT in (wei), e.g. 5 DAT --> 5000000000000000000
     * @param value amount of cents costs for GB downloaded
     */
    function setCostsPerGBDataDownloaded(uint value) onlyAdmins public {
        //hold old value for event
        uint oldValue = costsPerGBDownloaded;

        //set new value
        costsPerGBDownloaded = value;

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
    function getStorageCosts(uint256 size, uint duration) public view returns (uint) {
        //calc costs per day / byte
        uint256 costsForGB = costsPerGBData;
        uint256 costsPerDay = costsForGB.div(30);
        uint256 costsPerDayPerByte = costsPerDay.div(1073741824);

        //return costs for given size and duration
        return costsPerDayPerByte.mul(duration).mul(size);
    }

    /**
     * @dev Calculate the traffic costs for given sizes and downloads
     * @param size the size of data that will be stored
     * @param downloads amount of downloads estimated
     */
    function getTrafficCosts(uint256 size, uint downloads) view public returns (uint) {
        return costsPerGBDownloaded.div(1073741824).mul(size).mul(downloads);
    }

    /**
    * @dev Calculate the traffic costs for given traffic amount
    * @param estimatedGB amount GB of traffic estimated
    */
    function getTrafficCostsGB(uint256 estimatedGB) view public returns (uint) {
        return costsPerGBDownloaded.mul(estimatedGB);
    }
}