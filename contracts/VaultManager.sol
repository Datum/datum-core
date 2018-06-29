pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Operator.sol';


/**
 * @title VaultManager
 * Contract to all locked amount and deposits, controlled by parent contract
  */
contract VaultManager is Operator {

     //safe math for all uint256 types
    using SafeMath for uint256;

    //holds the locked amounts
    mapping(address => uint256) public lockedAmounts;

    //holds the locked amount for a data item for an address
    mapping(bytes32 => mapping(address => uint256)) public storageVault;

    
    constructor() public {
    }


    /**
     * @dev Allows the user to withdrawal from his vault
     * @param _value Amount to withdrawal
     */
    function transfer(uint256 _value) onlyOperator public  {
        require (lockedAmounts[msg.sender] >= _value);

        lockedAmounts[msg.sender] = lockedAmounts[msg.sender].sub(_value);

        msg.sender.transfer(_value);
    }

    /**
     * @dev Get Balance for address
     * @param _address public key address
     */
    function getBalance(address _address) public constant returns(uint256) 
    {
        return lockedAmounts[_address];
    }

    /**
     * @dev Get Storage Balance for address
     * @param _address public key address
     */
    function getStorageBalance(address _address, bytes32 _id) public constant returns(uint256) 
    {
        return storageVault[_id][_address];
    }

    /**
     * @dev Add balance to virtual wallet (onlyOperator)
     * @param _address public key address
     * @param _value amount to add
     */
    function addBalance(address _address, uint256 _value) onlyOperator public
    {
        lockedAmounts[_address] = lockedAmounts[_address].add(_value);
    }

    /**
     * @dev Add balance to virtual storage wallet (onlyOperator)
     * @param _address public key address
     * @param _value amount to add
     */
    function addStorageBalance(address _address, bytes32 _id, uint256 _value) onlyOperator public 
    {
        storageVault[_id][_address] = storageVault[_id][_address].add(_value);
    }

    /**
     * @dev Remove balance from virtual wallet (onlyOperator)
     * @param _address public key address
     * @param _value amount to add
     */
    function subtractBalance(address _address, uint256 _value) onlyOperator public
    {
        lockedAmounts[_address] = lockedAmounts[_address].sub(_value);
    }

     /**
     * @dev Remove balance from storage wallet (onlyOperator)
     * @param _address public key address
     * @param _value amount to add
     */
    function subtractStorageBalance(address _address, bytes32 _id, uint256 _value) onlyOperator public
    {
        storageVault[_id][_address] = storageVault[_id][_address].sub(_value);
    }
}