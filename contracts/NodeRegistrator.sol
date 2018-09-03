pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Operator.sol';
import './VaultManager.sol';
import './lib/Strings.sol';
import './ForeverStorage.sol';
import "./snarks/Verifier.sol";


/**
 * @title NodeRegistrator
 * Contract to hold all storage nodes in datum network
  */
contract NodeRegistrator is Operator {
     //safe math for all uint256 types
    using SafeMath for uint256;
    using Strings for *;

    //default vault manager used for locking money in contract
    VaultManager public vault; //address of vault manager
    ForeverStorage public foreverStorage; //storage contract

    //set default min deposit amount
    uint public nodeRegisterDepositAmount = 1 ether;

    //set default max deposit amount
    uint public nodeRegisterMaxDepositAmount = 1000000 ether;

    //maximal allowed storage nodes
    uint public maxStorageNodes = 100;

    bool public registrationOpen = true;

    //Storage node registered Event
    event NodeRegistered(address indexed storageNode, string endpoint, uint bandwidth, uint region);

    //Storage updated registered Event
    event NodeUpdated(address indexed storageNode, string endpoint, uint bandwidth, uint region);

    //Storage node unregister Event
    event NodeUnRegistered(address storageNode);

     //Storage node start unregister Event
    event NodeStartUnRegister(address storageNode, uint256 timestamp);

    //Storage node unregister Event
    event RewardCollected(address storageNode, uint256 value);

     //event fired if deposit
    event Deposit(address owner, uint256 amount);

    event StorageProofSuccessFull(address indexed storageNode, bytes32 indexed dataHash);

    event StorageProofSuccessFailed(address indexed storageNode, bytes32 indexed dataHash);

    constructor() public {
        //by default a new vault manager is created, can be overwritten with setVaultManager
        vault = new VaultManager();
        //foreverStorage = new ForeverStorage();
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
     * @dev Allows to open or close node registration
     * @param _state true / false
     */
    function setRegistrationState(bool _state) onlyOperator public 
    {
        registrationOpen = _state;
    }

    
    /**
     * @dev Allows the current operator to set a new storage.
     * @param _foreverStorageAddress The address of the deployed vault manager
     */
    function setStorage(address _foreverStorageAddress) onlyOperator public 
    {
        foreverStorage = ForeverStorage(_foreverStorageAddress);
    }

    //get acutal staking balance
    function getStakingBalance() public view returns(uint256) {
        return vault.getBalance(msg.sender);
    }


    //returns the max amount of allowed storage for given msg.sender in MB
    function getMaxStorageAmount(address nodeAddress
    ) public view returns(uint256) {
        return vault.getBalance(nodeAddress).div(500).div(1000000000000000);
    }

     /**
     * @dev Allows the current operator to set a new registerNodeDepositAmount.
     * @param amount Amount that a new node must deposit to register himself
     */
    function setRegisterNodeDepositAmount(uint amount) onlyOperator public {
        nodeRegisterDepositAmount = amount;
    }

      /**
     * @dev Allows the current operator to set a new max amount of storage nodes
     * @param amount Amount of max storage nodes
     */
    function setMaxStorageNodes(uint amount) onlyOperator public {
        maxStorageNodes = amount;
    }


    /**
    * @dev Deposit DATCoins to the Storage node Staking space
    */
    function deposit() payable public {
        //check for max amount
        require(vault.getBalance(msg.sender).add(msg.value) <= nodeRegisterMaxDepositAmount, "max amount exceedes");

        //add to locked vault balance
        vault.addBalance(msg.sender,msg.value);

        //fire event
        emit Deposit(msg.sender, msg.value);
    }

     /**
     * @dev Register a new storage node in datum network
     * @param endpoint Endpoint address of storage node
     * @param bandwidth Bandwith provided
     * @param region Region where node is based
     */
    function registerNode(string endpoint, uint256 bandwidth, uint256 region) payable public {

        //check if node already exists, if yes update data only
        if(foreverStorage.getBoolByBytes32(keccak256(msg.sender, "NodeExists"))) {
            foreverStorage.setStringByBytes32(keccak256(msg.sender, "NodeEndPoint"), endpoint);
            foreverStorage.setUintByBytes32(keccak256(msg.sender, "NodeRegion"), region);
            foreverStorage.setUintByBytes32(keccak256(msg.sender, "NodeBandwidth"), bandwidth);

            emit NodeUpdated(msg.sender, endpoint, bandwidth, region);

            return;
        }

        require(registrationOpen == true, "Registration is closed at moment");
        
        //key for node list
        bytes32 keyNodeList = keccak256("NodeList");

        //get actual node list
        address[] memory nodeList = foreverStorage.getAddressesByBytes32(keyNodeList);

        //check max amount of storage nodes is reached
        require(nodeList.length < maxStorageNodes, "max amount of storage nodes is reached");

        //add to locked amount for address if value is bigger than 0
        if(msg.value > 0) 
        {
            //check for max amount
            require(vault.getBalance(msg.sender).add(msg.value) <= nodeRegisterMaxDepositAmount, "max amount exceedes");

            //add to locked vault balance
            vault.addBalance(msg.sender,msg.value);

            //fire event
            emit Deposit(msg.sender, msg.value);
        }

        //min amount must be sent or lockedAmounts must have at least 
        require(msg.value >= nodeRegisterDepositAmount || vault.getBalance(msg.sender) >= nodeRegisterDepositAmount, "you have to provide a staking within this transaction or with deposit");

        //check if master node based on endpoint address
        bool isMasterNode = false;
        Strings.slice memory s = endpoint.toSlice();
        if(s.endsWith(".datum.org".toSlice())) {
            isMasterNode = true;
        } 
       
        
        //set to storage
        foreverStorage.setStringByBytes32(keccak256(msg.sender, "NodeEndPoint"), endpoint);
        foreverStorage.setUintByBytes32(keccak256(msg.sender, "NodeRegion"), region);
        foreverStorage.setUintByBytes32(keccak256(msg.sender, "NodeBandwidth"), bandwidth);
        foreverStorage.setStringByBytes32(keccak256(msg.sender, "NodeStatus"), "active");
        foreverStorage.setBoolByBytes32(keccak256(msg.sender, "NodeIsMasterNode"), isMasterNode);
        foreverStorage.setBoolByBytes32(keccak256(msg.sender, "NodeExists"), true);
        foreverStorage.setAddressesByBytes32(keyNodeList, msg.sender);
        
        //throw event for new nodes registered
        emit NodeRegistered(msg.sender, endpoint, bandwidth, region);
    }
  
     /**
     * @dev Start and unregistrationg Process for the storage node
     */
    function unregisterNodeStart() public {
        bool bExists = nodeExists(msg.sender);

        //check if msg.sender is a registered node and exists in mapping
        require(bExists, "your node is not a registered node in network");      

        //set to unregister list
        bytes32 keyNodeUnregisterStart = keccak256(msg.sender, "NodeUnregisterStart");
        foreverStorage.setUintByBytes32(keyNodeUnregisterStart, now);
        foreverStorage.setStringByBytes32(keccak256(msg.sender, "NodeStatus"), "unregister");

        //fire event
        emit NodeStartUnRegister(msg.sender, now);
        
    }

    function nodeExists(address node) public view returns(bool) {
        return foreverStorage.getBoolByBytes32(keccak256(node, "NodeExists"));
    }

    function getNodeCount() public view returns(uint256) {
        return foreverStorage.getAddressesByBytes32(keccak256("NodeList")).length;
    }

    /**
     * @dev Unregister a node after challenge period ended
     */
    function unregisterNode() public {

        //check if msg.sender is a registered node and exists in mapping
        require(nodeExists(msg.sender), "your node is not a registered node in network");

        bytes32 keyNodeUnregisterStart = keccak256(msg.sender, "NodeUnregisterStart");

        //only allow if challenge time eas exceeded
        require(block.timestamp > (foreverStorage.getUintByBytes32(keyNodeUnregisterStart) + 1 days), "the challenge time is not over, please wait");

        //delete from mapping
        foreverStorage.deleteBoolByBytes32(keccak256(msg.sender, "NodeExists"));
        foreverStorage.deleteAddressesByBytes32(keccak256("NodeList"), msg.sender);

        //delete infos
        foreverStorage.deleteStringByBytes32(keccak256(msg.sender, "NodeEndPoint"));
        foreverStorage.deleteUintByBytes32(keccak256(msg.sender, "NodeRegion"));
        foreverStorage.deleteUintByBytes32(keccak256(msg.sender, "NodeBandwidth"));
        foreverStorage.deleteStringByBytes32(keccak256(msg.sender, "NodeStatus"));
        foreverStorage.setBoolByBytes32(keccak256(msg.sender, "NodeExists"), false);

        //send tokens
        msg.sender.transfer(vault.getBalance(msg.sender));

        //fire vent
        emit NodeUnRegistered(msg.sender);
    }

    /**
     * @dev Get storage node endpoint address only
     * @param _address Address of the node
     */
    function getNodeEndpoint(address _address) public constant returns(string) 
    {
        return foreverStorage.getStringByBytes32(keccak256(_address, "NodeEndPoint"));
    }

     /**
     * @dev Get storage node status 
     * @param _address Address of the node
     */
    function getNodeStatus(address _address) public constant returns(string) 
    {
        return foreverStorage.getStringByBytes32(keccak256(_address, "NodeStatus"));
    }

    /**
     * @dev Generate random index number from existsing nodes
     * @param seed seed for randomness
     */
    function getRandomNode(uint seed) public constant returns (address) {

        bytes32 keyNodeList = keccak256("NodeList");
        address[] memory nodeAddresses = foreverStorage.getAddressesByBytes32(keyNodeList);
        return nodeAddresses[uint(keccak256(blockhash(block.number-1), seed ))%nodeAddresses.length];
        
    } 


    /**
     * @dev Get all infos about a node
     */
    function getNodeInfo(address node)
    public
    view
    returns (
        string endpoint,
        uint bandwidth,
        uint region,
        string status) {

        bytes32 keyStatus = keccak256(node, "NodeStatus");
        bytes32 keyEndpoint = keccak256(node, "NodeEndPoint");
        bytes32 keyRegion = keccak256(node, "NodeRegion");
        bytes32 keyBandwith = keccak256(node, "NodeBandwidth");

        return (
        foreverStorage.getStringByBytes32(keyEndpoint),
        foreverStorage.getUintByBytes32(keyBandwith),
        foreverStorage.getUintByBytes32(keyRegion),
        foreverStorage.getStringByBytes32(keyStatus));

    } 


    //checks if 
    function verifyProof(
    bytes32[] _proof,
    bytes32 _root,
    bytes32 _leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
        bytes32 proofElement = _proof[i];

        if (computedHash < proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
            // Hash(current element of the proof + current computed hash)
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == _root;
    }

    
     //called from storage nodes to proof that the really stored this data
    function giveForcedStorageProof(bytes32 dataHash, bytes32[] proof, bytes32 leafHash) public {
        //check if proof request exists
        require(foreverStorage.getUintByBytes32(keccak256(dataHash, msg.sender, "StorageProofRequestTimestamp")) > 0, "No forced proof exists the given storagenoNode (msg.sender)");

        //get merkle root of item
        bytes32 merkle_root = foreverStorage.getBytes32ByBytes32(keccak256(dataHash, "StorageItemMerkleRoot"));

        //check if proof was valid and if yes, remove from mapping to prevent further penalty for node
        bool bValid = verifyProof(proof, merkle_root, leafHash);
        if(bValid) {
            //delete from mapping

            //Check if proof was given in set timespan
            uint proofRequested = foreverStorage.getUintByBytes32(keccak256(dataHash, msg.sender, "StorageProofRequestTimestamp"));
            if((now - proofRequested < 250) || 
            (foreverStorage.getBoolByBytes32(keccak256(dataHash, msg.sender,  "StorageProofWorkStatus")) && now - proofRequested < 6000))
            {
                if(foreverStorage.getBoolByBytes32(keccak256(dataHash, msg.sender,  "StorageProofSnarksVerified"))) {
                    foreverStorage.deleteUintByBytes32(keccak256(dataHash, msg.sender, "StorageProofRequestTimestamp"));
                    foreverStorage.deleteAllAddressesByBytes32(keccak256(dataHash, msg.sender, "StorageProofRequestCreator"));
                    foreverStorage.deleteUintByBytes32(keccak256(dataHash, msg.sender, "StorageProofRequestChunk"));
                    foreverStorage.deleteBytes32ArrayByBytes32(keccak256(msg.sender, "StorageProofsForAddress"), dataHash);

                    //fire event
                    emit StorageProofSuccessFull(msg.sender, dataHash);
                }
            }
        } else {
            //fire event
            emit StorageProofSuccessFailed(msg.sender, dataHash);
        }
    }
    


      function estimateRewards() public returns(uint256) {
        //get all hashes stored by this node
        bytes32[] memory hashes = foreverStorage.getBytes32ArrayByBytes32(keccak256(msg.sender, "ItemsForNode"));

        uint256 rewards = 0;
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

            rewards = rewards.add(realCosts);
        }

        return rewards;
    }
}