pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './shared/Pausable.sol';
import './VaultManager.sol';
import './NodeRegistrator.sol';
import './ForeverStorage.sol';



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
    ForeverStorage private foreverStorage; //shared data storage

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

    //event if a storage node claim his rewards
    event StorageNodeRewarded(bytes32 dataHash, address storageNode, uint256 value);

    //event fired if deposit to storage contract
    event Deposit(address sender, address owner, uint256 amount);

    event Withdrawal(address owner, uint256 amount);

    event StorageProofNeeded(address indexed storageNode, bytes32 indexed dataHash, uint chunkIndex);
    
    event StorageNodesSelected(bytes32 dataHash, address addresses);

    constructor(address _vault, address _registrator) public {
        vault = VaultManager(_vault);
        registrator = NodeRegistrator(_registrator);
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
    * @dev Allows the current owner to set a storage contract (gandalf)
    * @param _foreverStorage The address of the deployed costs contract
    */
    function setStorageContract(address _foreverStorage) onlyOwner public
    {
        foreverStorage = ForeverStorage(_foreverStorage);
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
     * @dev Allows a party to add a data item to the contract.
     * @param owner The owner of the data
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     * @param merkleRoot root the root hash of the merkle tree
     * @param key The keyname used for this item
     * @param size The size of data in bytes   
     * @param replicationMode The replication mode of the data, 1-100
     * @param trusted list of wallets that have access
     */
    function setStorage(
        address owner,
        bytes32 dataHash,
        bytes32 merkleRoot,
        bytes32 key,
        uint256 size,
        uint256 replicationMode,
        address[] trusted
    )  public payable returns(address[]) {


        //if msg.value is provided, add to balance
        if(msg.value > 0) {
            vault.addBalance(msg.sender, msg.value);
            emit Deposit(msg.sender, msg.sender, msg.value);
        }
        
        //TOD: calculate minimum of locked tockens needed for init the storage for this id
        require(vault.getBalance(msg.sender) >= storageRegisterDepositAmount, "your deposit doens't must match the minimum deposit amount" );

        //check for costs
        //require(vault.getBalance(msg.sender) >= storageCosts, "your deposit amount must contents at least the storage costs for 1 day");

        //set storage
        foreverStorage.setAddressByBytes32(keccak256(dataHash, "StorageItemCreator"), msg.sender);
        foreverStorage.setAddressByBytes32(keccak256(dataHash, "StorageItemOwner"), owner);
        foreverStorage.setBytes32ByBytes32(keccak256(dataHash, "StorageItemHash"), dataHash);
        foreverStorage.setBytes32ByBytes32(keccak256(dataHash, "StorageItemMerkleRoot"), merkleRoot);
        foreverStorage.setUintByBytes32(keccak256(dataHash, "StorageItemSize"), size);
        foreverStorage.setUintByBytes32(keccak256(dataHash, "StorageItemCreated"), now);
        foreverStorage.setBytes32ByBytes32(keccak256(dataHash, "StorageItemKey"), key);
        foreverStorage.setUintByBytes32(keccak256(dataHash, "StorageItemReplicationMode"), replicationMode);

        //update counts
        uint storageItemCount = foreverStorage.getUintByBytes32(keccak256("StorageItemCount"));
        foreverStorage.setUintByBytes32(keccak256("StorageItemCount"), storageItemCount.add(1));


        //set trusted addresses
        foreverStorage.setAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"), owner);
        foreverStorage.setBytes32ArrayByAddress(owner, dataHash);
        for(uint i =0; i < trusted.length;i++) {
            foreverStorage.setAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"), trusted[i]);
        }

        //set mappings and key mappings
        foreverStorage.setBytes32ArrayByBytes32(keccak256(owner, "StorageItemsForOwner"), dataHash);
        if(key != 0x0) {
            foreverStorage.setBytes32ArrayByBytes32(keccak256(owner, key, "StorageItemsForKey"), dataHash);
        }
        
        //fire event
        emit StorageItemAdded(msg.sender, owner, dataHash);

        //get storage nodes
        address[] memory a = new address[](3);
        a[0] = registrator.getRandomNode(now);
        a[1] = registrator.getRandomNode(now + 10);
        //try to get different nodes
        uint exitCount = 1;
        while(exitCount < 10) {
            a[2] = registrator.getRandomNode(now + exitCount);
            if(a[2] != a[1]) break;
            exitCount++;
        }

        //set as target nodes and inverse mappings
        foreverStorage.setAddressesByBytes32(keccak256(dataHash, "StorageItemNodes"), a[0]);
        foreverStorage.setAddressesByBytes32(keccak256(dataHash, "StorageItemNodes"), a[1]);
        foreverStorage.setAddressesByBytes32(keccak256(dataHash, "StorageItemNodes"), a[2]);
        foreverStorage.setBytes32ArrayByBytes32(keccak256(a[0], "ItemsForNode"), dataHash);
        foreverStorage.setBytes32ArrayByBytes32(keccak256(a[1], "ItemsForNode"), dataHash);
        foreverStorage.setBytes32ArrayByBytes32(keccak256(a[1], "ItemsForNode"), dataHash);

        //fire events
        emit StorageNodesSelected(dataHash, a[0]);
        emit StorageNodesSelected(dataHash, a[1]);
        emit StorageNodesSelected(dataHash, a[2]);

        return a;
    }

    //force a storage node to proof that it really stored the data with given hash
    function forceStorageProof(bytes32 dataHash, address storageNode) public {

        //check if given storageNode is responsible for given dataHash
        address[] memory nodes = foreverStorage.getAddressesByBytes32(keccak256(dataHash, "StorageItemNodes"));
        bool bResponsible = false;
        for(uint i = 0; i < nodes.length;i++) {
            if(nodes[i] == storageNode) {
                bResponsible = true;
                break;
            }
        }
        
        require(bResponsible, "storageNode is node responsible for this item");

        //select random chunk index from data stored, should return pseudo random number;
        uint randomChunk = uint(keccak256(block.timestamp))%32;

        //set storage
        foreverStorage.setUintByBytes32(keccak256(dataHash, storageNode, "StorageProofRequestTimestamp"), now);
        foreverStorage.setAddressesByBytes32(keccak256(dataHash, storageNode, "StorageProofRequestCreator"), msg.sender);
        foreverStorage.setUintByBytes32(keccak256(dataHash, storageNode, "StorageProofRequestChunk"), randomChunk);
        foreverStorage.setBytes32ArrayByBytes32(keccak256(storageNode, "StorageProofsForAddress"), dataHash);

        //Fire event that can be checked by storage nodes
        emit StorageProofNeeded(storageNode, dataHash, randomChunk);

    }

    //update the status for given storage node 
    function setWorkStatusOnStorageProof(bytes32 dataHash) public {
        foreverStorage.setBoolByBytes32(keccak256(dataHash, msg.sender,  "StorageProofWorkStatus"), true);
    }

    //adds access to another address for given item
    function addAccess(bytes32 dataHash, address wallet) public returns(bool success) {
        //only owner can add/remove access
        require(foreverStorage.getAddressByBytes32(keccak256(dataHash, "StorageItemOwner")) == msg.sender, "Only owner can change access rules");

        //set new address as trusted
        foreverStorage.setAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"), wallet);

        //fire event
        emit StorageItemPublicKeyAdded(msg.sender, dataHash, wallet);

        return true;
    }

    //removes access of wallet for a given item
    function removeAccess(bytes32 dataHash,address wallet) whenNotPaused public returns(bool success) {
        //only owner can add/remove access
        require(foreverStorage.getAddressByBytes32(keccak256(dataHash, "StorageItemOwner")) == msg.sender, "Only owner can change access rules");

        //set new address as trusted
        foreverStorage.deleteAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"), wallet);

        //fire event
        emit StorageItemPublicKeyRemoved(msg.sender, dataHash, wallet);

        return true;
    }


    //called from storage node to collect rewards
    function collectRewards() public {
        //get all hashes stored by this node
        bytes32[] memory hashes = foreverStorage.getBytes32ArrayByBytes32(keccak256(msg.sender, "ItemsForNode"));

        //go trough all and calculate rewards / check for storage proofs
        for(uint i = 0; i < hashes.length;i++) {

            //last paid
            uint lastPaid = foreverStorage.getUintByBytes32(keccak256(msg.sender, hashes[i], "StorageItemLastPaid")); 
            uint itemCreatedAt = foreverStorage.getUintByBytes32(keccak256(hashes[i], "StorageItemCreated"));
            uint256 itemSize = foreverStorage.getUintByBytes32(keccak256(hashes[i], "StorageItemSize"));

            //calculate time to be payed for
            uint timeToBePaidInSeconds = now.sub(itemCreatedAt).sub(lastPaid);

            //storage costs for  1 day for 1 byte
            uint256 costs = 500000000000000 wei;
            uint256 costsBytePerDay = costs.div(1024).div(30);
            uint256 costsItemPerDay = costsBytePerDay.mul(itemSize);

            //calculate real costs/reward
            uint256 realCosts = costsItemPerDay.mul(timeToBePaidInSeconds).div(24).div(60).div(60);
            
            //get the address that makes the deposit for this item
            address depositer = foreverStorage.getAddressByBytes32(keccak256(hashes[i], "StorageItemCreator"));

            //check if enough balance is there
            if(vault.getBalance(depositer) >= realCosts) {
                vault.subtractBalance(depositer, realCosts);
                vault.addBalance(msg.sender, realCosts);
                emit StorageNodeRewarded(hashes[i], msg.sender, realCosts);

            } else {
                //get total amount exists on balance and delete item
                uint256 depositerAmount = vault.getBalance(depositer);
                vault.subtractBalance(depositer,depositerAmount);
                vault.addBalance(msg.sender, depositerAmount);
                removeDataItem(hashes[i]);

                emit StorageNodeRewarded(hashes[i], msg.sender, depositerAmount);
            }

            
            //set last paid date for this item
            foreverStorage.setUintByBytes32(keccak256(msg.sender, hashes[i], "StorageItemLastPaid"), now); 
        }
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
    function removeKey(bytes32 keyname) whenNotPaused public returns(bool success) {
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
    function removeDataItem(bytes32 dataHash) whenNotPaused public returns(bool) {
        require(foreverStorage.getAddressByBytes32(keccak256(dataHash, "StorageItemOwner")) == msg.sender, "Only owner can remove item");
        
        //remove storages
        foreverStorage.deleteAddressByBytes32(keccak256(dataHash, "StorageItemCreator"));
        foreverStorage.deleteAddressByBytes32(keccak256(dataHash, "StorageItemOwner"));
        foreverStorage.deleteBytes32ByBytes32(keccak256(dataHash, "StorageItemHash"));
        foreverStorage.deleteBytes32ByBytes32(keccak256(dataHash, "StorageItemMerkleRoot"));
        foreverStorage.deleteUintByBytes32(keccak256(dataHash, "StorageItemSize"));
        foreverStorage.deleteUintByBytes32(keccak256(dataHash, "StorageItemCreated"));
        foreverStorage.deleteBytes32ByBytes32(keccak256(dataHash, "StorageItemKey"));
        foreverStorage.deleteUintByBytes32(keccak256(dataHash, "StorageItemReplicationMode"));


        //update count
        uint storageItemCount = foreverStorage.getUintByBytes32(keccak256("StorageItemCount"));
        foreverStorage.setUintByBytes32(keccak256("StorageItemCount"), storageItemCount.sub(1) );


        //remove array storages
        foreverStorage.deleteAllAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"));
        foreverStorage.deleteBytes32ArrayByBytes32(keccak256(msg.sender, "StorageItemsForOwner"), dataHash);

        //removenodes
        foreverStorage.deleteAllAddressesByBytes32(keccak256(dataHash, "StorageItemNodes"));

        //fire event
        emit StorageItemRemoved(dataHash);

        return true;
    }


    /**
     * @dev Get count of storage items
     */
    function getStorageItemCount() public constant returns(uint entityCount) {
        return foreverStorage.getUintByBytes32(keccak256("StorageItemCount"));
    }

    /**
     * @dev Check if the signed message has access to given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function canKeyAccessData(bytes32 dataHash, bytes32 signedMessage, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {

        //recover signers public key
       address signer = recoverAddress(signedMessage,v,r,s);
       address[] memory trusted = foreverStorage.getAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"));

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
     * @dev Check if the signed message has access to given data id
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function canKeyUpdateData(bytes32 dataHash, bytes32 signedMessage, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        //recover signers public key
       address signer = recoverAddress(signedMessage,v,r,s);
       return foreverStorage.getAddressByBytes32(keccak256(dataHash, "StorageItemOwner")) == signer;
    }

    /**
     * @dev Get array of all public keys that have access to this data tiem
     * @param dataHash The id of the data item, which represents the sha256 hash of content
     */
    function getAccessKeysForData(bytes32 dataHash) public view returns (address[]) {
        return foreverStorage.getAddressesByBytes32(keccak256(dataHash, "StorageItemTrusted"));
    }

    /**
     * @dev Get data it from user set key for this item
     * @param key the key name for the data id
     */
    function getIdsForKey(bytes32 key) public view returns (bytes32[]) {
        return foreverStorage.getBytes32ArrayByBytes32(keccak256(msg.sender, key, "StorageItemsForKey"));
    }

    /**
    * @dev Get last version for this key
    * @param key the key name for the data id
    */
    function getActualIdForKey(address wallet, bytes32 key) public view returns (bytes32) {
        bytes32[] memory ids =  foreverStorage.getBytes32ArrayByBytes32(keccak256(wallet, key, "StorageItemsForKey"));
        return ids[ids.length -1];
    }

    /**
     * @dev Get all data id's for given account
     */
    function getIdsForAccount(address wallet) public view returns (bytes32[]) {
        return foreverStorage.getBytes32ByAddress(wallet);
    }


    /**
     * @dev Get all responsible nodes for an item
     */
    function getNodesForItem(bytes32 dataHash) public view returns(address[]) {
        return foreverStorage.getAddressesByBytes32(keccak256(dataHash, "StorageItemNodes"));
    }


    /**
    * @dev Get all data id's for given account with given key
    */
    function getIdsForAccountByKey(address wallet, bytes32 key) public view returns(bytes32[]) {
         return  foreverStorage.getBytes32ArrayByBytes32(keccak256(wallet, key, "StorageItemsForKey"));
    }


    /**
     * @dev Get specified storage item by given id
     */
    function getItemForId(bytes32 dataHash)
    public
    constant
    returns (
        address sender,
        address owner,
        bytes32 merkle ,
        uint256 size,
        bytes32  keyname,
        uint replicationMode ,
        uint createdAt) {

        return(
        foreverStorage.getAddressByBytes32(keccak256(dataHash, "StorageItemCreator")),
        foreverStorage.getAddressByBytes32(keccak256(dataHash, "StorageItemOwner")),
        foreverStorage.getBytes32ByBytes32(keccak256(dataHash, "StorageItemMerkleRoot")),
        foreverStorage.getUintByBytes32(keccak256(dataHash, "StorageItemSize")),
        foreverStorage.getBytes32ByBytes32(keccak256(dataHash, "StorageItemKey")),
        foreverStorage.getUintByBytes32(keccak256(dataHash, "StorageItemReplicationMode")),
        foreverStorage.getUintByBytes32(keccak256(dataHash, "StorageItemCreated"))
        );
    }

     function recoverAddress(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address) {
        return ecrecover(hash, v, r, s);
    }
}
