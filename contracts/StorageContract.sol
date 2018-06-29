pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './VaultManager.sol';
import './NodeRegistrator.sol';


/**
 * @title StorageContract
 * Contract to hold all data items that lives in the datum network
 * The storage nodes will access/validate all acess and read/write operation with this contract
 */
contract StorageNodeContract is Ownable {

    //safe math for all uint256 types
    using SafeMath for uint256;

    VaultManager public vault; //address of vault manager
    NodeRegistrator public registrator; //address of node registrator


    //block time is fix 5 seconds
    uint private monthInBlocks =  12 * 60 * 24 * 30;

    //storage costs in test version fix depending on size, ~5$/GB per month, --> 1 DAT = 0.023 --> ~217 DATCoins/GB per month
    //set default min deposit amount, 1 ether = 1 DATCoins, which allow ~4.6MB per month stored
    uint public storageRegisterDepositAmount = 1 ether;

    //meta data about a storage item
    struct StorageItem {
        bytes32 id;
        bytes32 keyname;
        uint replicationMode;
        uint privacy;
        uint duration;
        uint createdAt;
    }

    struct StorageProof {
        address owner;
        bytes32 proof;
        uint downloaded;
    }

    mapping(address => mapping(bytes32 => bytes32[])) public storageKeys;
    mapping(bytes32 => StorageItem) public storageItemMapping;
    
    bytes32[] public storageItemList;

    mapping(address => bytes32[]) public storageItems;

    //holds all public keys that have access to a given dataId
    mapping(bytes32 => address[]) storageItemAccessList;

    mapping(bytes32 => mapping(address => bytes)) storageItemCryptedSecrets;

    mapping(bytes32 => address) public allowedStorageNodesForDataId;

    //hold the proof of storage node that a data is stored
    mapping(bytes32 => StorageProof[]) public storageProofs;

    //events

    //Storage "deal" created with amount holded in contract
    event StorageInitialized(address owner, bytes32 dataHash, uint256 amount);

    //Storage item added to contract
    event StorageItemAdded(address owner, bytes32 id, uint replicationMode, uint privacy, uint duration);

    //storage item removed
    event StorageItemRemoved(bytes32 dataHash);

    //add new item to key
    event StorageItemAddedToKeySpace(address owner, bytes32 key, bytes32 dataHash);

    //Public Key added to access list
    event StorageItemPublicKeyAdded(address owner, bytes32 dataHash, address publicKey);

    //public Key removed from access list
    event StorageItemPublicKeyRemoved(address owner, bytes32 dataHash, address publicKey);

    //storage node selected
    event StorageEndpointSelected(bytes32 dataHash, address storageNode, string endpoint);

    //event if a storage node claim his rewards
    event StorageNodeRewarded(bytes32 dataHash, address storageNode, uint256 value);

    //proof from storage node added
    event StorageProofAdded(bytes32 dataHash, address storageNode);

    //event fired if deposit to storage contract
    event Deposit(address owner, uint256 amount);

    constructor() public {
        vault = new VaultManager();
        registrator = new NodeRegistrator();
    }


    /**
     * @dev Allows the current owner to set a new Vault Manager.
     * @param _vaultManagerAddress The address of the deployed vault manager
     */
    function setVaultManager(address _vaultManagerAddress) onlyOwner public 
    {
        vault = VaultManager(_vaultManagerAddress);
    }

    /**
     * @dev Allows the current owner to set a new Node Registrator contract.
     * @param _registratorAddress The address of the deployed node registrator contract
     */
    function setRegistrator(address _registratorAddress) onlyOwner public 
    {
        registrator = NodeRegistrator(_registratorAddress);
    }



    /**
     * @dev Allows the current operator to set a new storageDepositAmount.
     * @param amount Amount that a new storage user must deposit
     */
    function setStorageDepositAmount(uint amount) onlyOwner public {
        storageRegisterDepositAmount = amount;
    }


   /**
   * @dev Deposit DATCoins to the Storage space
   */
   function deposit() payable public {
       vault.addBalance(msg.sender, msg.value);

       emit Deposit(msg.sender, msg.value);
   }


    /**
     * @dev Allows a party to add a data item to the contract.
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param key The keyname used for this item
     * @param replicationMode The replication mode of the data, 1-100
     * @param privacy The privacy level of the data , 1-3
     * @param duration The duration of the storage deal in days
     */
    function initStorage(
        bytes32 dataHash, bytes32 key, uint replicationMode,
        uint privacy, uint duration) public payable returns (string) {

        //check if the transaction contents a msg.value to fill the contract, if you make deposit
        if(msg.value != 0)
        {
            //add to vault
            vault.addBalance(msg.sender, msg.value);

            //fire event
            emit Deposit(msg.sender, msg.value);
        }

        //TOD: calculate minimum of locked tockens needed for init the storage for this id
        require(vault.getBalance(msg.sender) >= storageRegisterDepositAmount);

        //add msg.sender as main owner and first in access control list
        storageItemAccessList[dataHash].push(msg.sender);

        //store storage items per public key
        StorageItem memory item = StorageItem(dataHash, key, replicationMode,privacy,duration, block.number);
        storageItemMapping[dataHash] = item;

        //add to users storage item list
        storageItems[msg.sender].push(dataHash);

        //push to index array
        storageItemList.push(dataHash);

        //if key provided, add to key mapping
        if(key != 0) {
            //add key / id to mapping for user
            storageKeys[msg.sender][key].push(dataHash);
        }

        //remove deposit amount from lockedamount and add to storage locked amounts
        vault.subtractBalance(msg.sender, storageRegisterDepositAmount);
        
        //add to storage locked balance       
        vault.addStorageBalance(msg.sender, dataHash,  storageRegisterDepositAmount);

        //fire event
        emit StorageInitialized(msg.sender, dataHash, storageRegisterDepositAmount);

        //fire event
        emit StorageItemAdded(msg.sender, dataHash, replicationMode, privacy, duration);

        //TODO: get random node with criteria
        address nodeAddrses = registrator.getRandomNode(block.number);
        allowedStorageNodesForDataId[dataHash] = nodeAddrses;
        string memory nodeEndpoint = registrator.getNodeEndpoint(nodeAddrses);

        //fire event
        emit StorageEndpointSelected(dataHash, nodeAddrses, nodeEndpoint);

        //return storage node endpoint
        return nodeEndpoint;
    }


    /**
     * @dev Get locked balance in contract for given msg.sender
     */
    function getLockedBalance() public view returns(uint256) {
        return vault.getBalance(msg.sender);
    }

    /**
     * @dev Adds a new id to the keyspace
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param key The key to add the id to
     * @param clear flag if clear old entries and reset the key space
     */
    function setIdForKey(bytes32 dataHash, bytes32 key, bool clear) public {
        //add new data hash to key space
        if(key != 0) {

            //if clear requested, reset the complete array with id's for this keyname
            if(clear) {
                storageKeys[msg.sender][key] = new bytes32[](0);
            }

            //add key / id to mapping for user
            storageKeys[msg.sender][key].push(dataHash);

            //fire vent
            emit StorageItemAddedToKeySpace(msg.sender, key, dataHash);
        }
    }


    /**
     * @dev Allows a storage node to claim his rewards for a given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
     
    function claimStorageReward(bytes32 dataHash) public {
        //only the storage node for this id can claim rewards
        require(allowedStorageNodesForDataId[dataHash] == msg.sender);

        //check if the storage deal is fullfilled
        StorageItem memory item = storageItemMapping[dataHash];
        uint blocksDuration = item.duration / 5;
        require((item.createdAt + blocksDuration) >= block.number);

        //get owner of storage item
        address owner = storageItemAccessList[dataHash][0];

        //get amount locked for this storage item
        uint value = vault.getStorageBalance(owner, dataHash);

        //remove from storage balance
        vault.subtractStorageBalance(msg.sender, dataHash, value);

        //send reward to storage node address
        msg.sender.transfer(value);

        //fire event
        emit StorageNodeRewarded(dataHash, msg.sender, value);
    }
    

    /**
     * @dev Allows the data owner to add another public key to ACL
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param publicKey The public key of the user that receives access
     * @param encryptedSecret The encrypted secret for this public key (can be decrypted with his private key)
     */
     
    function addStorageAccessKey(bytes32 dataHash, address publicKey, bytes encryptedSecret) public {
        //main owner of data item must be msg.sender
        require(storageItemAccessList[dataHash][0] == msg.sender);

        //add the new publicKey that can access the data
        storageItemAccessList[dataHash].push(publicKey);

        //add encrypted secret for public key
        storageItemCryptedSecrets[dataHash][publicKey] = encryptedSecret;

        //fire public event that key is added
        emit StorageItemPublicKeyAdded(msg.sender, dataHash, publicKey);
    }


     /**
     * @dev Allows the data owner to remove public key from ACL
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param publicKey The public key of the user that receives access
     */
     
    function removeStorageAccessKey(bytes32 dataHash, address publicKey) public {
        //main owner of data item must be msg.sender
        require(storageItemAccessList[dataHash][0] == msg.sender);


        uint i = 0;
        while (storageItemAccessList[dataHash][i] != publicKey) {
            i++;
        }

        while (i<storageItemAccessList[dataHash].length-1) {
            storageItemAccessList[dataHash][i] = storageItemAccessList[dataHash][i+1];
            i++;
        }

        storageItemAccessList[dataHash].length--;


        //add encrypted secret for public key
        delete storageItemCryptedSecrets[dataHash][publicKey];

        //fire public event that key is added
        emit StorageItemPublicKeyRemoved(msg.sender, dataHash, publicKey);
    }
    

    /**
     * @dev Removes a data item from storage space
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function removeDataItem(bytes32 dataHash) public {
        //main owner of data item must be msg.sender
        require(storageItemAccessList[dataHash][0] == msg.sender);

        //delete access list
        delete storageItemAccessList[dataHash];

        //delete from item list
        delete storageItemMapping[dataHash];

        //push to index array
        storageItemList.push(dataHash);

        uint i = 0;
        while (storageItems[msg.sender][i] != dataHash) {
            i++;
        }

        while (i<storageItems[msg.sender].length-1) {
            storageItems[msg.sender][i] = storageItems[msg.sender][i+1];
            i++;
        }

        storageItems[msg.sender].length--;


        emit StorageItemRemoved(dataHash);
    }


    /**
     * @dev Add a signed proof that the data is stored on a storage node
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param signature Message signature hash
     * @param v 
     * @param r 
     * @param s 
     */
    function addStorageProof(bytes32 dataHash, bytes32 signature, uint8 v, bytes32 r, bytes32 s, uint downloaded) public {
        //verify signature is from msg.sender
        require(verify(signature, v, r, s, msg.sender));

        //verfiy id is related to msg.sender storage node
        require(allowedStorageNodesForDataId[dataHash] == msg.sender);

        //add proof to list
        storageProofs[dataHash].push(StorageProof(msg.sender,signature, downloaded));

        //fire event
        emit StorageProofAdded(dataHash, msg.sender);
    }
    
    

    /**
     * @dev Read the public secret for given data if and msg.sender
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getEncryptedSecret(bytes32 dataHash) public view returns(bytes) {
        return storageItemCryptedSecrets[dataHash][msg.sender];
    }


    /**
     * @dev Get count of storage items
     */
    function getStorageItemCount() public constant returns(uint entityCount) {
        return storageItemList.length;
    }

    /**
     * @dev Check if the signed message has access to given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param signedMessage The signed message
     * @param v crypto values
     * @param r crypto values
     * @param s crypto values
     */
    function canKeyAccessData(bytes32 dataHash, bytes32 signedMessage, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        bool bCanAccess = false;

        //recover signers public key
        address addressFromSignedMessage = recoverAddress(signedMessage,v,r,s);

        //check ACL if public key has access
        for(uint i = 0; i < storageItemAccessList[dataHash].length;i++ )
        {
            if(storageItemAccessList[dataHash][i] == addressFromSignedMessage)
            {
                bCanAccess = true;
            }
        }
        return (bCanAccess);
    }

    /**
     * @dev Check if a given public key can store data, if deposit is in vault manager
     */
    function canStoreData() public view returns (bool) {
        return vault.getBalance(msg.sender) > 10;
    }

    /**
     * @dev Get array of all public keys that have access to this data tiem
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getAccessKeysForData(bytes32 dataHash) public view returns (address[]) {
        return storageItemAccessList[dataHash];
    }

    /**
     * @dev Get data it from user set key for this item
     * @param key the key name for the data id
     */
    function getIdsForKey(bytes32 key) public view returns (bytes32[]) {
        return storageKeys[msg.sender][key];
    }

     /**
     * @dev Get last version for this key
     * @param key the key name for the data id
     */
    function getActualIdForKey(bytes32 key) public view returns (bytes32) {
        return storageKeys[msg.sender][key][storageKeys[msg.sender][key].length -1];
    }

    /**
     * @dev Get all data id's for given account
     */
    function getIdsForAccount() public view returns (bytes32[]) {
        return storageItems[msg.sender];
    }

    /**
     * @dev Get all data id's exists in the contract
     */
    function getAllIds() public view returns (bytes32[]) {
        return storageItemList;
    }

    /**
     * @dev Get specified storage item by given id
     */
    function getItemForId(bytes32 id) public view returns (bytes32,bytes32,uint, uint , uint, uint) {
      StorageItem memory item = storageItemMapping[id];
      return (item.id, item.keyname, item.replicationMode, item.privacy, item.duration, item.createdAt);
    }

    /**
     * @dev Check if given public key can store given dataHash
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param publicKey Public Key of the storage node
     */
    function canNodeStoreId(bytes32 dataHash, address publicKey) public view returns (bool)
    {
        return allowedStorageNodesForDataId[dataHash] == publicKey;
    }

     /**
     * @dev Recover address from signed message
     */
    function recoverAddress(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address) {

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, hash);
        return ecrecover(prefixedHash, v, r, s);
    }


    /**
     * @dev Check if signed message is from given public key
     */
    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s, address key) internal pure returns(bool) {

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, hash);
        return ecrecover(prefixedHash, v, r, s) == key;
    }

    /**
     * @dev return substring of given string with start and end index
     */
    function substring(string str, uint startIndex, uint endIndex) internal pure returns (string) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
  
}


