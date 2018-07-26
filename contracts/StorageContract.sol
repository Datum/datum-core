pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './shared/Pausable.sol';
import './VaultManager.sol';
import './NodeRegistrator.sol';
import './StorageCostsContract.sol';


/**
 * @title StorageContract
 * Contract to hold all data items that lives in the datum network
 * The storage nodes will access/validate all acess and read/write operation with this contract
 */
contract StorageNodeContract is Pausable {

    //safe math for all uint256 types
    using SafeMath for uint256;

    VaultManager public vault; //address of vault manager
    NodeRegistrator public registrator; //address of node registrator
    StorageCostsContract public costsContract; //costs contract


    //block time is fix 5 seconds
    uint private monthInBlocks =  12 * 60 * 24 * 30;

    //storage costs in test version fix depending on size, ~5$/GB per month, --> 1 DAT = 0.023 --> ~217 DATCoins/GB per month
    //set default min deposit amount, 1 ether = 1 DATCoins, which allow ~4.6MB per month stored
    uint public storageRegisterDepositAmount = 10000000000000000 wei;

    //meta data about a storage item
    struct StorageItem {
        address creator;
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

    //define param (isPaused) to decide availability of this version smart contract
    //isPaused = false : all functions are callable by Datum SDK and will return normal response
    //isPaused = true  : all functions will return "This version had been deprecated, Please upgrade Datum SDK npm package" about calling from SDK

    StorageItem[] public items;
    mapping(bytes32 => uint) public hashToIdMap;
    mapping(bytes32 => address[]) public itemToAddressMap;
    mapping(address => bytes32[]) public addressToItemMap;
    mapping(bytes32 => mapping(address => bytes32[])) public keyToItemMap;
    mapping(bytes32 => bytes) secretsMap;

    mapping(bytes32 => address) deletedMapping;

    //Storage "deal" created with amount holded in contract
    event StorageInitialized(address owner, bytes32 dataHash, uint256 amount);

    //Storage item added to contract
    event StorageItemAdded(address owner, bytes32 id);

    //storage item removed
    event StorageItemRemoved(bytes32 dataHash);

    //Public Key added to access list
    event StorageItemPublicKeyAdded(address owner, bytes32 dataHash, address publicKey);

    //public Key removed from access list
    event StorageItemPublicKeyRemoved(address owner, bytes32 dataHash, address publicKey);

    //event if a storage node claim his rewards
    event StorageNodeRewarded(bytes32 dataHash, address storageNode, uint256 value);

    //event fired if deposit to storage contract
    event Deposit(address sender, address owner, uint256 amount);

    event Withdrawal(address owner, uint256 amount);


    constructor(address _vault, address _costs) public {
        vault = VaultManager(_vault);
        costsContract = StorageCostsContract(_costs);
        //registrator = new NodeRegistrator();
    }


    /**
     * @dev Allows the current owner to set a new Vault Manager.
     * @param _vaultManagerAddress The address of the deployed vault manager
     */
    function setVaultManager(address _vaultManagerAddress) onlyOwner whenNotPaused public
    {
        vault = VaultManager(_vaultManagerAddress);
    }

    /**
     * @dev Allows the current owner to set a new Node Registrator contract.
     * @param _registratorAddress The address of the deployed node registrator contract
     */
    function setRegistrator(address _registratorAddress) onlyOwner whenNotPaused public
    {
        registrator = NodeRegistrator(_registratorAddress);
    }

    /**
    * @dev Allows the current owner to set a new costs contract.
    * @param _costsContract The address of the deployed costs contract
    */
    function setCostsContract(address _costsContract) onlyOwner whenNotPaused public
    {
        costsContract = StorageCostsContract(_costsContract);
    }



    /**
     * @dev Allows the current operator to set a new storageDepositAmount.
     * @param amount Amount that a new storage user must deposit
     */
    function setStorageDepositAmount(uint amount) onlyOwner whenNotPaused public {
        storageRegisterDepositAmount = amount;
    }



    /**
    * @dev Deposit DATCoins to the Storage space
    */
    function deposit(address sender) payable public {
        vault.addBalance(sender, msg.value);

        emit Deposit(msg.sender, sender, msg.value);
    }

    /**
   * @dev Withdrawal DATCoins to the Storage space
   */
    function withdrawal(address sender, uint256 amount) whenNotPaused payable public {
        //check if amount is valid
        require(vault.getBalance(sender) >= amount);

        //substract from balance
        vault.subtractBalance(sender, msg.value);

        //Send tokens
        sender.transfer(amount);

        //fire event
        emit Withdrawal(sender, amount);
    }
   
    /**
     * @dev Allows a party to add a data item to the contract.
     * @param sender The owner of the data
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param merkleRoot root the root hash of the merkle tree
     * @param key The keyname used for this item
     * @param size The size of data in bytes
     * @param duration The duration of the storage deal in days     
     * @param replicationMode The replication mode of the data, 1-100
     * @param privacy The privacy level of the data , 1-3
     */
    function setStorage(
        address sender,
        bytes32 dataHash,
        bytes32 merkleRoot,
        bytes32 key,
        uint256 size,
        uint256 duration,
        uint256 replicationMode,
        uint256 privacy,
        bytes secret
    )  public payable {

        if(msg.value > 0) {
            vault.addBalance(sender, msg.value);

            emit Deposit(msg.sender, sender, msg.value);
        }

        //TOD: calculate minimum of locked tockens needed for init the storage for this id
        require(vault.getBalance(sender) >= storageRegisterDepositAmount);

        //check for costs
        require(vault.getBalance(sender) >= costsContract.getStorageCosts(size, duration));

        //change balances to item
        //remove deposit amount from lockedamount and add to storage locked amounts
        vault.subtractBalance(sender, costsContract.getStorageCosts(size, duration));

        //add to storage locked balance
        vault.addStorageBalance(sender, dataHash,  costsContract.getStorageCosts(size, duration));

        //fire event
        emit StorageInitialized(sender, dataHash, costsContract.getStorageCosts(size, duration));


        //store storage items per public key
        StorageItem memory item = StorageItem(msg.sender,sender, dataHash, merkleRoot, size, key, replicationMode,privacy,duration, block.number, true);

        // add item
        items.push(item);
        uint index = items.length -1;

        //add different mappings
        hashToIdMap[dataHash] = index;
        itemToAddressMap[dataHash].push(sender);
        addressToItemMap[sender].push(dataHash);
        secretsMap[dataHash] = secret;

        if(key != 0x0) {
            keyToItemMap[key][sender].push(dataHash);
        }

        //fire event
        emit StorageItemAdded(sender, dataHash);
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




    function removeFromAddressMapping(address user, bytes32 item) whenNotPaused public {
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
     * @param keyname The key of the data items
     */
    function removeKey(address sender, bytes32 keyname) whenNotPaused public {

        bytes32[] memory itemList = keyToItemMap[keyname][sender];

        for(uint i = 0; i < itemList.length;i++ )
        {
            //remove only items where msg.sender is the owner
           if(items[hashToIdMap[itemList[i]]].owner == sender)
           {
                removeDataItem(sender, itemList[i]);
           }
        }

        //delete key for msg.sender
        delete keyToItemMap[keyname][sender];
    }


    /**
     * @dev Removes a data item from storage space
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function removeDataItem(address sender, bytes32 dataHash) whenNotPaused public {
        //owner of data item must be msg.sender
        require(items[hashToIdMap[dataHash]].owner == sender);

        //delete item
        delete items[hashToIdMap[dataHash]];

        //delete mappings
        //delete itemToAddressMap[dataHash];
        //delete addressToItemMap[msg.sender];
        removeFromAddressMapping(sender, dataHash);

        delete hashToIdMap[dataHash];

        //fire event
        emit StorageItemRemoved(dataHash);

        //add historic
        deletedMapping[dataHash] =  sender;
    }



     /**
     * @dev check if wallet was deleter.
     */
    function hasDeletedItem(address wallet, bytes32 id) public view returns (bool) {
       return deletedMapping[id] == wallet;
    }

    /**
     * @dev Read the public secret for given data if and msg.sender
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getEncryptedSecret(bytes32 dataHash) public view returns(bytes) {
        return secretsMap[dataHash];
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
    function getActualIdForKey(address wallet, bytes32 key) public view returns (bytes32) {
        return keyToItemMap[key][wallet][keyToItemMap[key][wallet].length -1];
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
