pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './VaultManager.sol';
import './NodeRegistrator.sol';
import './StorageCostsContract.sol';


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
    StorageCostsContract public costsContract; //costs contract
 

    //block time is fix 5 seconds
    uint private monthInBlocks =  12 * 60 * 24 * 30;

    //storage costs in test version fix depending on size, ~5$/GB per month, --> 1 DAT = 0.023 --> ~217 DATCoins/GB per month
    //set default min deposit amount, 1 ether = 1 DATCoins, which allow ~4.6MB per month stored
    uint public storageRegisterDepositAmount = 1 ether;

    //meta data about a storage item
    struct StorageItem {
        address owner;
        bytes32 id;
        bytes32 merkle;
        uint256 size;
        bytes32 keyname;
        uint replicationMode;
        uint privacy;
        uint duration;
        uint createdAt;
        bool exists;
    }

    struct StorageProof {
        address signer;
        bytes32 proof;
    }


    StorageItem[] public items;
    mapping(bytes32 => uint) public hashToIdMap;
    mapping(bytes32 => address[]) public itemToAddressMap;
    mapping(address => bytes32[]) public addressToItemMap;
    mapping(bytes32 => mapping(address => bytes32[])) public keyToItemMap;
    mapping(address => mapping(bytes32 => bytes)) secretsForUserMap;

    //hold the proof of storage node that a data is stored
    mapping(bytes32 => StorageProof[]) public storageProofs;

    //events

    //Storage "deal" created with amount holded in contract
    event StorageInitialized(address owner, bytes32 dataHash, uint256 amount);

    //Storage item added to contract
    event StorageItemAdded(address owner, bytes32 id);

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

    event Withdrawal(address owner, uint256 amount);

    constructor() public {
        vault = new VaultManager();
        costsContract = new StorageCostsContract();
        //registrator = new NodeRegistrator();
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
     * @dev Allows the current owner to set a new costs contract.
     * @param _costsContract The address of the deployed costs contract
     */
    function setCostsContract(address _costsContract) onlyOwner public 
    {
        costsContract = StorageCostsContract(_costsContract);
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
   * @dev Withdrawal DATCoins to the Storage space
   */
   function withdrawal(uint256 amount) payable public {
       //check if amount is valid
       require(vault.getBalance(msg.sender) >= amount);

       //substract from balance
       vault.subtractBalance(msg.sender, msg.value);

       //Send tokens
       msg.sender.transfer(amount);

        //fire event
       emit Withdrawal(msg.sender, amount);
   }


    /**
     * @dev Allows a party to add a data item to the contract.
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param key The keyname used for this item
     * @param replicationMode The replication mode of the data, 1-100
     * @param privacy The privacy level of the data , 1-3
     * @param duration The duration of the storage deal in days
     */
    function setStorage(
        bytes32 dataHash, 
        bytes32 merkleRoot, 
        bytes32 key, 
        uint256 size,
        uint duration,
        uint replicationMode,
        uint privacy, 
        bytes secret
    ) public payable {

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

        //check for costs
        require(vault.getBalance(msg.sender) >= costsContract.getStorageCosts(size, duration));

        //change balances to item
        //remove deposit amount from lockedamount and add to storage locked amounts
        vault.subtractBalance(msg.sender, costsContract.getStorageCosts(size, duration));
        
        //add to storage locked balance       
        vault.addStorageBalance(msg.sender, dataHash,  costsContract.getStorageCosts(size, duration));

        //fire event
        emit StorageInitialized(msg.sender, dataHash, costsContract.getStorageCosts(size, duration));


        //store storage items per public key
        StorageItem memory item = StorageItem(msg.sender, dataHash, merkleRoot, size, key, replicationMode,privacy,duration, block.number, true);

        // add item
        items.push(item);
        uint index = items.length -1;

        //add different mappings
        hashToIdMap[dataHash] = index;
        itemToAddressMap[dataHash].push(msg.sender);
        addressToItemMap[msg.sender].push(dataHash);
        secretsForUserMap[msg.sender][dataHash] = secret;

        if(key != 0x0) {
            keyToItemMap[key][msg.sender].push(dataHash);
        }

        //fire event
        emit StorageItemAdded(msg.sender, dataHash);
    }


    /**
     * @dev Get locked balance in contract for given msg.sender
     */
    function getDepositBalance(address wallet) public view returns(uint256) {
        return vault.getBalance(wallet);
    }

    /**
     * @dev Get locked balance in contract for given msg.sender
     */
    function getTotalLockedBalance(address wallet) public view returns(uint256) {
        bytes32[] memory itemsForUser =  addressToItemMap[wallet];

        uint256 iTotal = 0;
        for(uint i = 0; i < itemsForUser.length;i++) {
            iTotal = iTotal + vault.getStorageBalance(wallet, itemsForUser[i]);
        }
        return iTotal;
    }

     /**
     * @dev Get locked balance in contract for given msg.sender
     */
    function getLockedBalanceForId(address wallet, bytes32 dataHash) public view returns(uint256) {
        return vault.getStorageBalance(wallet, dataHash);
    }

  
    /*
    function claimStorageReward(bytes32 dataHash) public {
        

        //only the storage node for this id can claim rewards
        require(allowedStorageNodesForDataId[dataHash] == msg.sender);

        //check if the storage deal is fullfilled
        
        StorageItem memory item = items[hashToIdMap[dataHash]];
        uint blocksDuration = item.duration / 5;
        require((item.createdAt + blocksDuration) >= block.number);

        //get owner of storage item
        address owner = item.owner;

        //get amount locked for this storage item
        uint value = vault.getStorageBalance(owner, dataHash);

        //remove from storage balance
        vault.subtractStorageBalance(msg.sender, dataHash, value);

        //send reward to storage node address
        msg.sender.transfer(value);

        //fire event
        emit StorageNodeRewarded(dataHash, msg.sender, value);
        
    }
    */
    

    /**
     * @dev Allows the data owner to add another public key to ACL
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param wallet The public key of the user that receives access
     * @param secret The encrypted secret for this public key (can be decrypted with his private key)
     */
     
    function addAccess(bytes32 dataHash, address wallet, bytes secret) public {
        //main owner of data item must be msg.sender
        require(items[hashToIdMap[dataHash]].owner == msg.sender);

        //add the new publicKey that can access the data
        secretsForUserMap[wallet][dataHash] = secret;
        addressToItemMap[wallet].push(dataHash);
        itemToAddressMap[dataHash].push(wallet);

        //fire public event that key is added
        emit StorageItemPublicKeyAdded(msg.sender, dataHash, wallet);
    }


     /**
     * @dev Allows the data owner to remove public key from ACL
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param wallet The public key of the user that receives access
     */
     
    function removeStorageAccessKey(bytes32 dataHash, address wallet) public {
        //main owner of data item must be msg.sender
        require(items[hashToIdMap[dataHash]].owner == msg.sender);

        //remove mappings
        delete secretsForUserMap[wallet][dataHash];

        removeFromAddressMapping(wallet, dataHash);

        //fire public event that key is added
        emit StorageItemPublicKeyRemoved(msg.sender, dataHash, wallet);
    }
    

    function removeFromAddressMapping(address user, bytes32 item) public {

        bytes32[] storage acl = addressToItemMap[user];
        address[] storage aclInvert = itemToAddressMap[item];

        uint i = 0;
        while (acl[i] != item) {
            i++;
        }

         while (i<acl.length-1) {
            acl[i] = acl[i+1];
            i++;
        }
        acl.length--;

        i = 0;
        while (aclInvert[i] != user) {
            i++;
        }

         while (i<aclInvert.length-1) {
            aclInvert[i] = aclInvert[i+1];
            i++;
        }
        aclInvert.length--;
    }

    /**
     * @dev Removes a data item from storage space
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function removeDataItem(bytes32 dataHash) public {
        //owner of data item must be msg.sender
        require(items[hashToIdMap[dataHash]].owner == msg.sender);

        //delete item
        delete items[hashToIdMap[dataHash]];

        //delete mappings
        delete itemToAddressMap[dataHash];
        delete addressToItemMap[msg.sender];
        delete hashToIdMap[dataHash];

        //fire event
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
    function addStorageProof(bytes32 dataHash, bytes32 signature, uint8 v, bytes32 r, bytes32 s) public {
        //verify signature is from msg.sender
        require(verify(signature, v, r, s, msg.sender));

        //verfiy id is related to msg.sender storage node
        //require(allowedStorageNodesForDataId[dataHash] == msg.sender);

        //add proof to list
        storageProofs[dataHash].push(StorageProof(msg.sender,signature));

        //fire event
        emit StorageProofAdded(dataHash, msg.sender);
    }
    
    

    /**
     * @dev Read the public secret for given data if and msg.sender
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getEncryptedSecret(bytes32 dataHash) public view returns(bytes) {
        return secretsForUserMap[msg.sender][dataHash];
    }


    /**
     * @dev Get count of storage items
     */
    function getStorageItemCount() public constant returns(uint entityCount) {
        return items.length;
    }

    /**
     * @dev Check if the signed message has access to given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param signer The signer address
     */
    function canKeyAccessData(bytes32 dataHash, address signer) public view returns(bool) {
        bool bCanAccess = false;

        bytes32[] memory acl = addressToItemMap[signer];

        //check ACL if public key has access
        for(uint i = 0; i < acl.length;i++ )
        {
            if(acl[i] == dataHash)
            {
                bCanAccess = true;
            }
        }
        return (bCanAccess);
    }

    /**
     * @dev Get array of all public keys that have access to this data tiem
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getAccessKeysForData(bytes32 dataHash) public view returns (address[]) {
        return itemToAddressMap[dataHash];
    }

    /**
     * @dev Get data it from user set key for this item
     * @param key the key name for the data id
     */
    function getIdsForKey(bytes32 key) public view returns (bytes32[]) {
       return keyToItemMap[key][msg.sender];
    }

     /**
     * @dev Get last version for this key
     * @param key the key name for the data id
     */
    function getActualIdForKey(bytes32 key) public view returns (bytes32) {
        
        return keyToItemMap[key][msg.sender][keyToItemMap[key][msg.sender].length -1];
    }

    /**
     * @dev Get all data id's for given account
     */
    function getIdsForAccount(address wallet) public view returns (bytes32[]) {
        return addressToItemMap[wallet];
    }


     /**
     * @dev Get all data id's for given account with given key
     */
    function getIdsForAccountByKey(address wallet, bytes32 key) public view returns(bytes32[]) {
        return keyToItemMap[key][wallet];
    }

 
    /**
     * @dev Get specified storage item by given id
     */
    function getItemForId(bytes32 dataHash) 
        public 
        constant 
        returns (
            address owner, 
            bytes32 id,
            bytes32 merkle ,
            uint256 size, 
            bytes32  keyname, 
            uint replicationMode , 
            uint privacy, 
            uint duration,
            uint createdAt,
            bool exists) {
    
                uint index = hashToIdMap[dataHash];
                StorageItem memory item = items[index];
                return (
                    item.owner,
                    item.id, 
                    item.merkle, 
                    item.size,
                    item.keyname, 
                    item.replicationMode, 
                    item.privacy, 
                    item.duration, 
                    item.createdAt,
                    item.exists
                );
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


