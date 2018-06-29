pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Operator.sol';
import './VaultManager.sol';


/**
 * @title NodeRegistrator
 * Contract to hold all storage nodes in datum network
  */
contract NodeRegistrator is Operator {

     //safe math for all uint256 types
    using SafeMath for uint256;


    VaultManager public vault; //address of vault manager

    //set default min deposit amount
    uint public nodeRegisterDepositAmount = 1 ether;

    //define regions
    enum Regions { AMERICA , EUROPE, ASIA, AUSTRALIA, AFRICA }

    //define bandwithds
    enum Bandwidths { LOW, MEDIUM, HIGH }

     //meta data about a storage node
    struct StorageNodeInfo {
        string endpoint;
        Bandwidths bandwidth;
        Regions region;
        bool exists;
        uint index;
    }

    //mapping for nodes
    mapping(address => StorageNodeInfo) public registeredNodes;

    //array for random
    address[] nodesArray;

    //Storage node registered Event
    event NodeRegistered(address storageNode, string endpoint, Bandwidths bandwidth, Regions region);

    //Storage node unregister Event
    event NodeUnRegistered(address storageNode);

    //Storage node unregister Event
    event RewardCollected(address storageNode, uint256 value);


    
    constructor() public {
        vault = new VaultManager();
    }


    /**
     * @dev Allows the current operator to set a new Vault Manager.
     * @param _vaultManagerAddress The address of the deployed vault manager
     */
    function setVaultManager(address _vaultManagerAddress) onlyOperator public 
    {
        vault = VaultManager(_vaultManagerAddress);
    }

     /**
     * @dev Allows the current operator to set a new registerNodeDepositAmount.
     * @param amount Amount that a new node must deposit to register himself
     */
    function setRegisterNodeDepositAmount(uint amount) onlyOperator public {
        nodeRegisterDepositAmount = amount;
    }


     /**
     * @dev Register a new storage node in datum network
     * @param endpoint Endpoint address of storage node
     * @param bandwidth Bandwith provided
     * @param region Region where node is based
     */
    function registerNode(string endpoint, Bandwidths bandwidth, Regions region) payable public {

        //min amount must be sent or lockedAmounts must have at least 
        require(msg.value >= nodeRegisterDepositAmount || vault.getBalance(msg.sender) >= nodeRegisterDepositAmount);

        //set msg.sender and endpoint in mapping
        registeredNodes[msg.sender] = StorageNodeInfo(endpoint,bandwidth,region,true, nodesArray.length);

        //add to array for random lookup
        nodesArray.push(msg.sender);

        //add to locked amount for address if value is bigger than 0
        if(msg.value > 0) 
        {
            vault.addBalance(msg.sender,msg.value);
        }

        //throw event for new nodes registered
        emit NodeRegistered(msg.sender, endpoint, bandwidth, region);
    }

       
     /**
     * @dev UnRegister a new storage node in datum network
     */
    function unregisterNode() public {

        //check if msg.sender is a registered node and exists in mapping
        require(registeredNodes[msg.sender].exists);

        //delete from index
        delete nodesArray[registeredNodes[msg.sender].index];

        //delete node
        delete registeredNodes[msg.sender];

        //throw event for removed node
        emit NodeUnRegistered(msg.sender);
        
    }


    /**
     * @dev Collect rewards for a storage node
     * @param _value Amount to collect
     */
    function collectRewards(uint256 _value) public {
        //check if msg.sender is a registered node and exists in mapping
        require(registeredNodes[msg.sender].exists);

        //virtual balanace must be higher
        require(vault.getBalance(msg.sender) >= _value);

        //substract from balance
        vault.subtractBalance(msg.sender, _value);

        //transfer 
        msg.sender.transfer(_value);

        //emit event
        emit RewardCollected(msg.sender, _value);
    }



    /**
     * @dev Get storage node info for given address
     * @param _address Address of the node
     */
    function getNode(address _address) public constant returns(string, Bandwidths, Regions ) 
    {
        return (registeredNodes[_address].endpoint,registeredNodes[_address].bandwidth,registeredNodes[_address].region);
    }

    /**
     * @dev Get storage node endpoint address only
     * @param _address Address of the node
     */
    function getNodeEndpoint(address _address) public constant returns(string) 
    {
        return registeredNodes[_address].endpoint;
    }

    /**
     * @dev Generate random index number from existsing nodes
     * @param seed seed for randomness
     */
    function getRandomNode(uint seed) public constant returns (address) {
        return nodesArray[uint(keccak256(blockhash(block.number-1), seed ))%nodesArray.length];
    } 
}