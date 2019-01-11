pragma solidity ^0.4.24;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './VaultManager.sol';
import './NodeRegistrator.sol';
import './ForeverStorage.sol';
import "./StorageKeys.sol";
import "./StorageData.sol";



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
    ForeverStorage public foreverStorage; //shared data storage
    StorageKeys public storageKeys;
    StorageData public storageData;

    //storage costs in test version fix depending on size, ~5$/GB per month, --> 1 DAT = 0.023 --> ~217 DATCoins/GB per month
    //set default min deposit amount, 1 ether = 1 DATCoins, which allow ~4.6MB per month stored
    uint public storageRegisterDepositAmount = 10000000000000000 wei;

    //Storage item added to contract
    event StorageItemAdded(address indexed sender, address indexed owner, bytes32 id);

    //storage item removed
    event StorageItemRemoved(bytes32 dataHash);

    //Public Key added to access list
    event StorageItemPublicKeyAdded(address indexed owner, bytes32 indexed dataHash, address indexed publicKey);

    //public Key removed from access list
    event StorageItemPublicKeyRemoved(address indexed owner, bytes32 indexed dataHash, address indexed publicKey);

    //event fired if deposit to storage contract
    event Deposit(address sender, address owner, uint256 amount);

    event Withdrawal(address owner, uint256 amount);

    event StorageProofNeeded(address indexed storageNode, bytes32 indexed dataHash, uint chunkIndex);
    
    event StorageNodesSelected(bytes32 dataHash, address addresses);

    constructor(address _vault, address _registrator, address _forever, address _storageKeys, address _storageData) public {
        vault = VaultManager(_vault);
        registrator = NodeRegistrator(_registrator);
        storageKeys = StorageKeys(_storageKeys);
        foreverStorage = ForeverStorage(_forever);
        storageData = StorageData(_storageData);
    }

    modifier onlyItemOwner(bytes32 dataHash) {
        if (foreverStorage.getAddressByBytes32(storageKeys.KeyItemOwner(dataHash)) != msg.sender) revert("Only allowed for item owner");
        _;
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
    * @dev Allows the current owner to set a storage contract (gandalf)
    * @param _foreverStorage The address of the deployed costs contract
    */
    function setStorageContract(address _foreverStorage) onlyOwner public
    {
        foreverStorage = ForeverStorage(_foreverStorage);
    }

    
     /**
    * @dev Allows the current owner to set a storage data
    * @param _storageData The address of the deployed storageata contract
    */
    function setStorageDataContract(address _storageData) onlyOwner public
    {
        storageData = StorageData(_storageData);
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
    function deposit(address sender) payable public {
        vault.addBalance(sender, msg.value);

        emit Deposit(msg.sender, sender, msg.value);
    }

    /**
   * @dev Withdrawal DATCoins to the Storage space
   */
    function withdrawal(address sender, uint256 amount) payable public {
        require(msg.sender == sender, "Only allow original signer of transactions to withdrawal to address");

        //check if amount is valid
        require(vault.getBalance(sender) >= amount, "requested withdrawal amount is higher than balance");

        //substract from balance
        vault.subtractBalance(sender, amount);

        //Send tokens
        sender.transfer(amount);

        //fire event
        emit Withdrawal(sender, amount);
    }


    /**
    * @dev adminWithdrawal Only used for migration
    */
    function adminWithdrawal(uint256 amount) public onlyOwner {
         //Send tokens
        msg.sender.transfer(amount);

        //fire event
        emit Withdrawal(msg.sender, amount);
    }
   
    /**
     * @dev Allows a party to add a data item to the contract.
     * @param owner The owner of the data
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param merkleRoot root the root hash of the merkle tree
     * @param key The keyname used for this item (string)
     * @param size The size of data in bytes   
     * @param replicationMode The replication mode of the data, 1-100
     * @param trusted list of wallets that have access
     */
    function setStorage(
        address owner,
        bytes32 dataHash,
        bytes32 merkleRoot,
        string key,
        uint256 size,
        uint256 replicationMode,
        address[] trusted
    )  public payable {

        if(foreverStorage.getUintByBytes32(storageKeys.KeyItemCreated(dataHash)) != 0) revert("E001");

        //if msg.value is provided, add to balance
        if(msg.value > 0) {
            deposit(msg.sender);
        }
        
        //TOD: calculate minimum of locked tockens needed for init the storage for this id
        if(vault.getBalance(msg.sender) < storageRegisterDepositAmount) revert("E002");

        //check for costs
        //require(vault.getBalance(msg.sender) >= storageCosts, "your deposit amount must contents at least the storage costs for 1 day");

        //set storage
        storageData.set(dataHash, msg.sender, owner, merkleRoot, size, key,replicationMode, trusted);
        
        //fire event
        emit StorageItemAdded(msg.sender, owner, dataHash);

        //get storage nodes
        address[] memory a = registrator.getRandomNodes(size, 3);

        //set node data
        storageData.setNode(a, dataHash, size);
       
        //fire events
        emit StorageNodesSelected(dataHash, a[0]);
        emit StorageNodesSelected(dataHash, a[1]);
        emit StorageNodesSelected(dataHash, a[2]);
    }



    function transferOwner(bytes32 dataHash, address newOwner) onlyItemOwner(dataHash) public {
        //set new owner
        foreverStorage.setAddressByBytes32(storageKeys.KeyItemOwner(dataHash), newOwner);
    }

    //adds access to another address for given item
    function addAccess(bytes32 dataHash, address wallet) onlyItemOwner(dataHash) public {
         require(storageData.addAccess(dataHash, wallet));
 
         emit StorageItemPublicKeyAdded(msg.sender, dataHash, wallet);
     }

    //removes access of wallet for a given item
    function removeAccess(bytes32 dataHash,address wallet) onlyItemOwner(dataHash) public {
        require(storageData.removeAccess(dataHash, wallet));

        emit StorageItemPublicKeyRemoved(msg.sender, dataHash, wallet);
    }

    
    /**
     * @dev Get locked balance in contract for given msg.sender
     */
    function getDepositBalance(address wallet) public view returns(uint256) {
        return vault.getBalance(wallet);
    }

     /**
     * @dev Removes a data item from storage space
     * @param keyname The key of the data items
     */
    function removeKey(string keyname) public returns(bool success) {
        bytes32[] memory items = getIdsForKey(keyname);
        for(uint i = 0;i < items.length;i++) 
        {
            removeDataItem(items[i]);
        }
        return true;
    }

    /**
     * @dev Removes a data item from storage space
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function removeDataItem(bytes32 dataHash) onlyItemOwner(dataHash) public {
        require(storageData.remove(msg.sender, dataHash));

        //fire event
        emit StorageItemRemoved(dataHash);

    }

    function hasItemDeleted(address owner, bytes32 dataHash) public view returns(bool) {
       return foreverStorage.getBoolByBytes32(storageKeys.KeyItemDeleted(dataHash));
    }

       //force a storage node to proof that it really stored the data with given hash
    function forceStorageProof(bytes32 dataHash, address storageNode) public {

        //check if given storageNode is responsible for given dataHash
        address[] memory nodes = foreverStorage.getAddressesByBytes32(storageKeys.KeyNodesForItem(dataHash));
        bool bResponsible = false;
        for(uint i = 0; i < nodes.length;i++) {
            if(nodes[i] == storageNode) {
                bResponsible = true;
                break;
            }
        }
        
        require(bResponsible, "storageNode is node responsible for this item");

        //select random chunk index from data stored, should return pseudo random number based on item size;
        uint randomChunk = uint(keccak256(abi.encodePacked(block.timestamp)))%(1+foreverStorage.getUintByBytes32(storageKeys.KeyItemSize(dataHash))/32)-1;

        //set storage
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeProofRequestTime(storageNode, dataHash), now);
        foreverStorage.setAddressArrayByBytes32(storageKeys.KeyNodeProofRequestCreator(storageNode, dataHash), msg.sender);
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeProofChunkRequested(storageNode, dataHash), randomChunk);
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyNodeProofRequestsForAddress(storageNode), dataHash);

        //Fire event that can be checked by storage nodes
        emit StorageProofNeeded(storageNode, dataHash, randomChunk);

    }


    function isItemDeleted(bytes32 dataHash) public constant returns(bool) {
        return foreverStorage.getBoolByBytes32(storageKeys.KeyItemDeleted(dataHash));
    }

    /**
     * @dev Get count of storage items
     */
    function getStorageItemCount() public constant returns(uint entityCount) {
        return foreverStorage.getUintByBytes32(storageKeys.KeyItemCount());
    }

    /**
     * @dev Check if the signed message has access to given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function canKeyAccessData(bytes32 dataHash, bytes32 signedMessage, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {

        //recover signers public key
       address signer = ecrecover(signedMessage,v,r,s);
       address[] memory trusted = foreverStorage.getAddressesByBytes32(storageKeys.KeyItemTrusted(dataHash));

       bool bHasAccess = false;
       for(uint i = 0;i < trusted.length;i++) {
           if(trusted[i] == signer) {
               bHasAccess = true;
               break;
           }
       }

       return bHasAccess;
    }

    /**
     * @dev Check if the given address has access to given id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param accessor The wallet address to check if has acccess
     */
     function canKeyAccessData(bytes32 dataHash, address accessor) public view returns(bool) {

        //recover signers public key
       address[] memory trusted = foreverStorage.getAddressesByBytes32(storageKeys.KeyItemTrusted(dataHash));

       bool bHasAccess = false;
       for(uint i = 0;i < trusted.length;i++) {
           if(trusted[i] == accessor) {
               bHasAccess = true;
               break;
           }
       }

       return bHasAccess;
    }

    /**
     * @dev Check if the signed message has access to given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function canKeyUpdateData(bytes32 dataHash, bytes32 signedMessage, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        //recover signers public key
       address signer = ecrecover(signedMessage,v,r,s);
       return foreverStorage.getAddressByBytes32(storageKeys.KeyItemOwner(dataHash)) == signer;
    }

    /**
     * @dev Get array of all public keys that have access to this data tiem
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getAccessKeysForData(bytes32 dataHash) public view returns (address[]) {
        return foreverStorage.getAddressesByBytes32(storageKeys.KeyItemTrusted(dataHash));
    }

    /**
     * @dev Get data it from user set key for this item
     * @param key the key name for the data id
     */
    function getIdsForKey(string key) public view returns (bytes32[]) {
        return foreverStorage.getBytes32ArrayByBytes32(storageKeys.KeyItemForKey(msg.sender, keccak256(abi.encodePacked(key))));
    }
    

    /**
    * @dev Get last version for this key
    * @param key the key name for the data id
    */
    function getActualIdForKey(address wallet, string key) public view returns (bytes32) {
        bytes32[] memory ids =  foreverStorage.getBytes32ArrayByBytes32(storageKeys.KeyItemForKey(wallet, keccak256(abi.encodePacked(key))));
        return ids[ids.length -1];
    }

    /**
     * @dev Get all data id's for given account
     */
    function getIdsForAccount(address wallet) public view returns (bytes32[]) {
        return foreverStorage.getBytes32ArrayByBytes32(storageKeys.KeyItemForAddress(wallet));
    }


    /**
     * @dev Get all responsible nodes for an item
     */
    function getNodesForItem(bytes32 dataHash) public view returns(address[]) {
        return foreverStorage.getAddressesByBytes32(storageKeys.KeyNodesForItem(dataHash));
    }


    /**
    * @dev Get all data id's for given account with given key
    */
    function getIdsForAccountByKey(address wallet, string key) public view returns(bytes32[]) {
         return  foreverStorage.getBytes32ArrayByBytes32(storageKeys.KeyItemForKey(wallet, keccak256(abi.encodePacked(key))));
    }


    /**
     * @dev Get specified storage item by given id
     */
    function getItemForId(bytes32 dataHash)
    public
    view
    returns (
        address owner,
        bytes32 merkle ,
        uint256 size,
        bytes32  keyname,
        uint replicationMode ,
        uint createdAt) {

        return(
        foreverStorage.getAddressByBytes32(storageKeys.KeyItemOwner(dataHash)),
        foreverStorage.getBytes32ByBytes32(storageKeys.KeyItemMerkle(dataHash)),
        foreverStorage.getUintByBytes32(storageKeys.KeyItemSize(dataHash)),
        foreverStorage.getBytes32ByBytes32(storageKeys.KeyItemKey(dataHash)),
        foreverStorage.getUintByBytes32(storageKeys.KeyItemReplication(dataHash)),
        foreverStorage.getUintByBytes32(storageKeys.KeyItemCreated(dataHash))
        );
    }
}
