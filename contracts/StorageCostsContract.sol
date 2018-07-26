pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './shared/Pausable.sol';


/**
 * @title StorageCostsContract
 * Contract to hold calculate storages and traffic costs
 */
contract StorageCostsContract is Pausable {
    using SafeMath for uint256;

    //value from 8th june 2018
    //1 DAT = $0,022444
    uint256 dollarRate = 22444; //remove leading 0

    //set default costs values in milli cents
    uint costsPerGBData = 500; //values set in cent values
    uint costsPerGBDownoaded = 100; //values set in cent values

    //define param (isPaused) to decide availability of this version smart contract
    //isPaused = false : all functions are callable by Datum SDK and will return normal response
    //isPaused = true  : all functions will return "This version had been deprecated, Please upgrade Datum SDK npm package" about calling from SDK


    event CoinValueChanged(address sender, uint oldValue, uint newValue);
    event CostsPerGBValueChanged(address sender, uint oldValue, uint newValue);
    event CostsPerGBDownloadedValueChanged(address sender, uint oldValue, uint newValue);

    modifier onlyPausableAdmins() {
        require(pausableAdmins[msg.sender] == true);
        _;
    }

    constructor() public {
        //make owner as a pausableAdmin
        pausableAdmins[owner] = true;
    }

    /**
     * @dev Add admins who can execute pause/resume function
     */
    function addPausableAdmin(address pausableAdmin) public onlyOwner {
        pausableAdmins[pausableAdmin] = true;
    }

    /**
     * @dev Remove admins who can execute pause/resume function
     */
    function removePausableAdmin(address pausableAdmin) public onlyOwner {
        pausableAdmins[pausableAdmin] = false;
    }

   

    /**
     * @dev Set the actual DAT/USD rate, the value must be provided in 10e6 milli cents, e.g. 1 DAT = $0,022364 --> 22364 micro cents
     * @param value amount of microcents
     */
    function setCoinDollarRate(uint value) onlyOwner public {
        //check contract status by checking isPaused param
        checkStatus();

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
        //check contract status by checking isPaused param
        checkStatus();

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
        //check contract status by checking isPaused param
        checkStatus();

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
        //check contract status by checking isPaused param
        checkStatus();

        return dollarRate;
    }


    /**
     * @dev Calculate the storage costs for given sizes and duration
     * @param size the size of data that will be stored
     * @param duration how long in days the data should be stored
     */
    function getStorageCosts(uint256 size, uint duration) public constant returns (uint) {
        //check contract status by checking isPaused param
        checkStatus();

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
        //check contract status by checking isPaused param
        checkStatus();

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
        //check contract status by checking isPaused param
        checkStatus();

        uint256 costsInDAT = 1 ether / dollarRate * 1000000;
        uint256 costsForDownloads = costsInDAT.mul(estimatedGB);
        return costsForDownloads;
    }
}