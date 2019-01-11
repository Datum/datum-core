pragma solidity ^0.4.24;

import './lib/SafeMath.sol';
import './shared/Administratable.sol';
import './VaultManager.sol';
import "./snarks/Verifier.sol";
import "./StorageKeys.sol";
import "./NodeRegistratorData.sol";


/**
 * @title NodeRegistrator
 * Contract to hold all storage nodes in datum network
  */
contract NodeRegistrator is Administratable {
     //safe math for all uint256 types
    using SafeMath for uint256;

    //default vault manager used for locking money in contract
    VaultManager public vault; //address of vault manager
    StorageKeys public storageKeys;
    NodeRegistratorData public nodeData;

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

    //event fired if deposit
    event AdminWithdrawal(address owner, uint256 amount);

    //event fired when VerifyZKProof is called
    event ZKProofVerified(bool verified);

    event StorageProofSuccessFull(address indexed storageNode, bytes32 indexed dataHash);

    event StorageProofFailed(address indexed storageNode, bytes32 indexed dataHash, uint timestamp);

    //event if a storage node claim his rewards
    event StorageNodeRewarded(bytes32 dataHash, address storageNode, uint256 value);

    constructor(address _vault, address _storageKeys, address _nodeData) public {
        //by default a new vault manager is created, can be overwritten with setVaultManager
        vault = VaultManager(_vault);
        storageKeys = StorageKeys(_storageKeys);
        nodeData = NodeRegistratorData(_nodeData);
    }

    /**
     * @dev Allows the current operator to set a new Vault Manager.
     * @param _vaultManagerAddress The address of the deployed vault manager
     */
    function setVaultManager(address _vaultManagerAddress) onlyAdmins public 
    {
        vault = VaultManager(_vaultManagerAddress);
    }

     /**
     * @dev Allows to open or close node registration
     * @param _state true / false
     */
    function setRegistrationState(bool _state) onlyAdmins public 
    {
        registrationOpen = _state;
    }
    
    /**
     * @dev Allows the current operator to set a new node data.
     * @param _nodeData The address of the deployed node data manager
     */
    function setNodeData(address _nodeData) onlyAdmins public 
    {
        nodeData = NodeRegistratorData(_nodeData);
    }

    //get acutal staking balance
    function getStakingBalance() public view returns(uint256) {
        return vault.getBalance(msg.sender);
    }

    //returns the max amount of allowed storage for given msg.sender in bytes
    function getMaxStorageAmount(address nodeAddress
    ) public view returns(uint) {
        if(nodeData.isAddressDatumNode(nodeAddress)) {
            //return max uint value;
            uint256 max = 2**256 - 1;
            return max;
        }
        return nodeData.getMaxStorageAmount(vault.getBalance(nodeAddress));
        
    }

     /**
     * @dev Allows the current operator to set a new registerNodeDepositAmount.
     * @param amount Amount that a new node must deposit to register himself
     */
    function setRegisterNodeDepositAmount(uint amount) onlyAdmins public {
        nodeRegisterDepositAmount = amount;
    }

      /**
     * @dev Allows the current operator to set a new max amount of storage nodes
     * @param amount Amount of max storage nodes
     */
    function setMaxStorageNodes(uint amount) onlyAdmins public {
        maxStorageNodes = amount;
    }

    function getNodeCount() public view returns(uint) {
        return nodeData.getNodeCount();
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
    * @dev adminWithdrawal Only used for migration
    */
    function adminWithdrawal(uint256 amount) public onlyOwner {
         //Send tokens
        msg.sender.transfer(amount);

        //fire event
        emit AdminWithdrawal(msg.sender, amount);
    }

     /**
     * @dev Register a new storage node in datum network
     * @param endpoint Endpoint address of storage node
     * @param bandwidth Bandwith provided
     * @param region Region where node is based
     */
    function registerNode(string endpoint, uint256 bandwidth, uint256 region) payable public {
        //check if node already exists, if yes update data only
        if(nodeData.nodeExists(msg.sender)) {
            //update node data
            nodeData.update(msg.sender, endpoint, bandwidth, region);
            //fire event
            emit NodeUpdated(msg.sender, endpoint, bandwidth, region);
            return;
        }

        require(registrationOpen == true, "Registration is closed at moment");
        
        //check max amount of storage nodes is reached
        require(nodeData.getNodeCount() < maxStorageNodes, "max amount of storage nodes is reached");

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
     
        //set to storage
        nodeData.set(msg.sender, endpoint, region, bandwidth);
        
        //throw event for new nodes registered
        emit NodeRegistered(msg.sender, endpoint, bandwidth, region);
    }



    /**
    * @dev Set the node to offline or online modus
    */
    function setNodeMode(bool bOnline) public {
        nodeData.setNodeMode(msg.sender, bOnline);
    }
  
     /**
     * @dev Start and unregistrationg Process for the storage node
     */
    function unregisterNodeStart() public {
        bool bExists = nodeData.nodeExists(msg.sender);

        //check if msg.sender is a registered node and exists in mapping
        require(bExists, "your node is not a registered node in network");      

        //set to unregister list
        nodeData.startUnregister(msg.sender);

        //fire event
        emit NodeStartUnRegister(msg.sender, now);
        
    }


    /**
     * @dev Unregister a node after challenge period ended
     */
    function unregisterNode() public {

        //check if msg.sender is a registered node and exists in mapping
        require(nodeData.nodeExists(msg.sender), "your node is not a registered node in network");

        //only allow if challenge time eas exceeded
        require(block.timestamp > (nodeData.getStartUnregisterDate(msg.sender) + 1 days), "the challenge time is not over, please wait");

        //remove node
        nodeData.remove(msg.sender);

        //send tokens
        msg.sender.transfer(vault.getBalance(msg.sender));

        //fire vent
        emit NodeUnRegistered(msg.sender);
    }

    /**
    * @dev Allow Operator to remove a node
    */
    function removeNodeFromAdmin(address _nodeAddress) public onlyAdmins {
        
        nodeData.remove(_nodeAddress);
        //fire vent
        emit NodeUnRegistered(_nodeAddress);
    }

     /**
     * @dev Generate random index number from existsing nodes
     * @param seed seed for randomness
     */
    function getRandomNode(uint seed) public constant returns (address) {
        address[] memory nodeAddresses = nodeData.getNodes();
        if(nodeAddresses.length == 0) return address(0);
        return nodeAddresses[uint(keccak256(abi.encodePacked(blockhash(block.number-1), seed )))%nodeAddresses.length];
    }

    /**
     * @dev Generate random index number from existsing datum nodes
     * @param seed seed for randomness
     */
    function getRandomDatumNode(uint seed) public constant returns (address) {
        address[] memory nodeAddresses = nodeData.getDatumNodes();
        if(nodeAddresses.length == 0) return address(0);
        return nodeAddresses[uint(sha3(blockhash(block.number-1), seed ))%nodeAddresses.length];
    }

    function nodeExistsInArray(address[] memory nodeList, address node) internal pure returns(bool) {
        for(uint i = 0; i < nodeList.length;i++) {
            if(nodeList[i] == node) {
                return true;
            }
        }
        return false;
    }

    function getSizeStoredByNode(address nodeAddress) public view returns(uint) {
        return nodeData.getSizeStoredByNode(nodeAddress);
    }

    /**
     * @dev Generate random index number from existsing nodes
     * @param count amount of  nodes
     */
    function getRandomNodes(uint256 minSize, uint count) public constant returns (address[]) {
        //check that node count don't exceeds total registrations
        require(nodeData.getNodeCount() >= count, "You requested more nodes than registrered");

        address[] memory a = new address[](count);
        uint defaultNodeCount = nodeData.getNodes().length;
        uint exitCount = 15;
        uint counter = 0;
        uint defaultNodesRequested = (count - 1) > defaultNodeCount ? defaultNodeCount : count -1;

        //get amount of nodes minus one, because last node will be always a datum node, but keep length of default nodes in mind
        for(uint i = 0; i < count;i++) {

            address nodeAddress = address(0);

            bool hasNodeEnoughSpace = true;

            if(i < defaultNodesRequested) {
                //get random non datum node
                nodeAddress = getRandomNode(now + i);
            } else {
                nodeAddress = getRandomDatumNode(now + i);
            }

            //check if selected node has enough space
            hasNodeEnoughSpace = (getMaxStorageAmount(nodeAddress) - nodeData.getSizeStoredByNode(nodeAddress)) > minSize;
            
            //add to list, if already exists try to get another
            while(nodeExistsInArray(a, nodeAddress) || !hasNodeEnoughSpace) {
                if(i < defaultNodesRequested) {
                    nodeAddress = getRandomNode(now + i + counter);
                } else {
                    nodeAddress = getRandomDatumNode(now + i + counter);
                }
                counter++;
                if(counter >= exitCount) {
                    nodeAddress = address(1);
                    break;
                }

                //check if selected node has enough space
                hasNodeEnoughSpace = (getMaxStorageAmount(nodeAddress) - nodeData.getSizeStoredByNode(nodeAddress)) > minSize;
            } 

            //set address
            a[i] = nodeAddress;
        }

        return a;
        
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
        string status,
        bool online,
        bool datumNode) {

        return nodeData.getNodeInfo(node);
    } 


    //checks if 
    function verifyMerkleProof(
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

    
    function VerifyZKProof (
        uint256[] alpha, 
        uint256[2][2] beta, 
        uint256[2][2] gamma, 
        uint256[2][2] delta, 
        uint256[2][3] gammaABC,
        uint256[] proofA,
        uint256[2][2] proofB,
        uint256[] proofC,
        uint256[] input,
        bytes32 dataHash) public 
	{
		Verifier.VerifyingKey memory vk;

        vk.beta = Pairing.G2Point(beta[0], beta[1]);
        vk.gamma = Pairing.G2Point(gamma[0], gamma[1]);
        vk.delta = Pairing.G2Point(delta[0], delta[1]);
		vk.alpha = Pairing.G1Point(alpha[0], alpha[1]);
		
        vk.gammaABC = new Pairing.G1Point[](3);
		vk.gammaABC[0] = Pairing.G1Point(gammaABC[0][0],gammaABC[0][1]);
        vk.gammaABC[1] = Pairing.G1Point(gammaABC[1][0],gammaABC[1][1]);
        vk.gammaABC[2] = Pairing.G1Point(gammaABC[2][0],gammaABC[2][1]);

        Verifier.Proof memory proof;
    	proof.B = Pairing.G2Point(proofB[0], proofB[1]);
		proof.A = Pairing.G1Point(proofA[0], proofA[1]);
		proof.C = Pairing.G1Point(proofC[0], proofC[1]);
	
        bool verified = Verifier.Verify(vk, proof, input);
        nodeData.setVerifiedProof(msg.sender, dataHash, verified);
        emit ZKProofVerified(verified);
	}
    
    

    
    //create transaction with all failed proofs as event
    function getFailedStorageProofs() public {
        bytes32[] memory hashes = nodeData.getProofs(msg.sender);

        //get only last 20
        uint maxCount = 20;
        for(uint i = 0;i < hashes.length;i++) {
            uint proofRequested = nodeData.getProofRequestTime(msg.sender, hashes[i]);
            if((now - proofRequested > 250) || 
            (nodeData.getProofWorkstatus(msg.sender, hashes[i]) && now - proofRequested > 300))
            {
                //failed proof
                emit StorageProofFailed(msg.sender, hashes[i], proofRequested);

                //break
                if(i >= maxCount)
                {
                    break;
                }
            }
            
        }
    }
    



    
     //called from storage nodes to proof that the really stored this data
    function giveForcedStorageProof(bytes32 dataHash, bytes32[] proof, bytes32 leafHash) public {
        //check if proof request exists
        require(nodeData.getProofRequestTime(msg.sender, dataHash) > 0, "No forced proof exists the given storagenoNode (msg.sender)");
        //get merkle root of item
        bytes32 merkle_root = nodeData.getMerkleRoot(dataHash);
        //get storage proof request time
        uint proofRequested = nodeData.getProofRequestTime(msg.sender, dataHash);
        //check if proof was valid and if yes, remove from mapping to prevent further penalty for node
        bool merkleProofValid = verifyMerkleProof(proof, merkle_root, leafHash);
        bool zkproofValid = nodeData.getVerifiedProof(msg.sender, dataHash);
        if(now - proofRequested < 300 && merkleProofValid && zkproofValid) {
            //delete proof if verified
            nodeData.removeProof(msg.sender, dataHash);
            //fire event
            emit StorageProofSuccessFull(msg.sender, dataHash);
        } else {
            //fire event
            emit StorageProofFailed(msg.sender, dataHash, now);
        }
    }


    function estimateRewards() public returns(uint256) {
        return collectRewards(false);
    }

    //called from storage node to collect rewards
    function collectRewards(bool bCollect) public returns(uint256){
        //get all hashes stored by this node
        bytes32[] memory hashes = nodeData.getItemsForNode(msg.sender);

        uint256 rewards = 0;

        //go trough all and calculate rewards / check for storage proofs
        for(uint i = 0; i < hashes.length;i++) {
            //calculate time to be payed for
            uint timeToBePaidInSeconds = now.sub(nodeData.getItemCreated(hashes[i])).sub(nodeData.getItemLastPaid(hashes[i], msg.sender));

            //storage costs for  1 day for 1 byte
            uint256 costs = 155220429 wei;
            uint256 costsItemPerDay = costs.div(1024).div(30).mul(nodeData.getItemSize(hashes[i]));

            //calculate real costs/reward
            uint256 realCosts = costsItemPerDay.mul(timeToBePaidInSeconds).div(24).div(60).div(60);
            rewards = rewards.add(realCosts);

            if(bCollect) {
                //get the address that makes the deposit for this item
                address depositer = nodeData.getItemCreator(hashes[i]);

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
                    //removeDataItem(hashes[i]);

                    emit StorageNodeRewarded(hashes[i], msg.sender, depositerAmount);
                }

                //set last paid date for this item
                nodeData.setItemLastPaid(hashes[i], msg.sender);
            }
        }

        return rewards;
    }

}