pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './VaultManager.sol';
import './identity/DatumRegistry.sol';
import './StorageContract.sol';


contract MarketplaceContract is Ownable {
    using SafeMath for uint256;


    bytes32[] public hashes;

    DataItem[] public items;

    VaultManager public vault; //address of vault manager
    StorageNodeContract public storageContract; //address of storage contract
    DatumRegistry public registry;


    mapping(bytes32 => SignedProofRequest) public signingProofRequests;

    //hold data items that are for sale for a given address
    mapping(address => bytes32[]) public dataItemsForAddress;

    //hold all items to by id
    mapping(bytes32 => uint) public hashToIdMap;

    //hold data requests
    mapping(address => mapping(bytes32 => Request[])) dataRequests;

    //hold data auctions for user
    mapping(address => bytes32[]) dataAuctionsForUser;

    //hold bids for user
    mapping(address => bytes32[]) auctionBidsForUser;

    //hold data auctions 
    mapping(bytes32 => Auction) public dataAuctions;

    //hold bids for single auction
    mapping(bytes32 => Bid[]) auctionBids;

    //event fired if data item added to marketplace
    event DataItemAdded(address owner, bytes32 id, uint amount, uint duration);

    //event fired if data item was bought
    event DataItemTraded(address owner, address buyer,  bytes32 id, uint amount);

    //event fired if data request added to marketplace
    event DataRequestAdded(address requester, string category, uint price, uint duration);

    //event fired if data auction added
    event DataAuctionAdded(address requester, bytes32 id);

    //event fired if data request cancelled
    event DataRequestCancelled(address requester, bytes32 id, uint256 amount);

    //event fired if bid set
    event AuctionBid(bytes32 id, address owner, uint256 amount);

    //event fired if auction closed
    event AuctionClosed(bytes32 id, address owner, address buyer, uint256 amount);

    //event fired if deposit
    event Deposit(address owner, uint256 amount);

    //event fired if withdrawal
    event Withdrawal(address id, uint256 amount);

    //event fired if a reward is received
    event RewardReceived(bytes32 indexed id, address indexed owner, address indexed receiver, uint256 amount);

    //event fired if signingproofRequest is created
    event SigningProofRequestCreated(bytes32 indexed id, address indexed creator);

    struct DataItem {
        address owner;
        bytes32 dataHash;
        uint256 price;
        bytes32 category;
        bytes metadata;
        bytes example;
        uint duration;
        bytes proof;
        bool exists;
    }

    struct Bid {
        address owner;
        uint256 amount;
        uint timestamp;
    }

    struct SignedProofRequest {
        address creator;
        uint256 reward;
        bytes32[] claimsNeededSetByCreator;
        bytes32 rewardModifierClaim;
        uint256[] extraRewardsAmount;
        bool exists;
        mapping(address => bool) claimed;
    }

    struct Request {
        bytes32 id;
        string category;
		uint price;
        uint duration;
        bool filled;
    }

    struct Auction {
        bytes32 id;
        address owner;
        uint256 minBid;
        uint256 bidStep;
        uint256 instantBuyPrice;
        uint256 lastBid;
        uint durationBlock;
        uint createdAtBlock;
        bool closed;
        bool exists;
    }

   //constructor
    constructor() public {
            vault = new VaultManager();
    }


    /**
     * @dev Set the active vault manager that handles the locked tokens and payments
     */
    function setVaultManager(address _vaultManagerAddress) onlyOwner public 
    {
        vault = VaultManager(_vaultManagerAddress);
    }

    /**
     * @dev Set the active storage 
     */
    function setStorage(address _storageAddress) onlyOwner public 
    {
        storageContract = StorageNodeContract(_storageAddress);
    }


    /**
     * @dev Set the active registry contract 
    */
    function setRegistry(address _registryAddress) onlyOwner public 
    {
        registry = DatumRegistry(_registryAddress);
    }


    /**
     * @dev Add data auction
     * @param duration how long the auction is active in blocks (5 second each block)
     * @param minBid the minimal amount for a bid
     * @param bidStep the minimal step for the next bid
     * @param instatBuyPrice bid to instant buy the item
     */
    function addAuction(bytes32 id, uint256 duration, uint256 minBid, uint256 bidStep, uint256 instatBuyPrice) public returns(bytes32) {
        //create id
        bytes32 auctionId = keccak256(abi.encodePacked(msg.sender, blockhash(block.number)));


        //push to auctions
       dataAuctions[auctionId] = Auction(id, msg.sender, minBid, bidStep, instatBuyPrice, 0, duration, block.number, false,true); 
       dataAuctionsForUser[msg.sender].push(auctionId);
       //dataAuctions[msg.sender][auctionId].push(Auction(auctionId, duration, minBid, bidStep, instatBuyPrice, 0));

       //fire event
       emit DataAuctionAdded(msg.sender, auctionId);

       return auctionId;
    }

    /**
     * @dev Add data request
     * @param category category for the request
     * @param price minimal price to fullfill the request
     * @param duration how long the request is active
     */
    function addRequest(string category, uint256 price, uint duration) payable public returns(bytes32) {
        //must supply value
        require(msg.value > 0);

        //create id
        bytes32 id = keccak256(abi.encodePacked(msg.sender, blockhash(block.number), category,price,duration));

        //add  to virtual balance
        vault.addStorageBalance(msg.sender,id, msg.value);

        //push request to msg.senders request list
       dataRequests[msg.sender][id].push(Request(id, category, price, duration,false));

       //fire event
       emit DataRequestAdded(msg.sender, category, price,duration);

        //return id
       return id;
    }


    /**
     * @dev Adds a sign proof request to the smart contract. Goal is that anyone can call this method an proof that
     *      he have a valid signature created by creator of this request. If yes, he ged rewarded
     * @param id id of the signProof request
     * @param reward the base reward in wei
     * @param claimsNeeded array of claims key names that needs to be exists and sigend by creator of proof request
     * @param rewardModifierClaim claim key name where the level is stored, if exists the amount in extraRewardAmounts will be added
     * @param extraRewardAmounts array of extra amount in wei that will be added depending on level got from modifier claim, e.g. [0, 0, 5, 15, 45, 95]
     */
    function addSigningProofRequest(bytes32 id, uint256 reward, bytes32[] claimsNeeded, bytes32 rewardModifierClaim, uint256[] extraRewardAmounts) public payable {
        //if extraReward provided, it needs to have length 6
        require(extraRewardAmounts.length == 0 || extraRewardAmounts.length == 6, "extra rewards array must have length 0 or 6");

        //create struct
        SignedProofRequest memory proofRequest = SignedProofRequest(msg.sender, reward, claimsNeeded, rewardModifierClaim, extraRewardAmounts, true);
        //add request id to mapping for given msg.sender
        signingProofRequests[id] = proofRequest;

        //if deposit was provided within same transaction add to vault
        if(msg.value != 0) {
            vault.addBalance(msg.sender, msg.value);
            emit Deposit(msg.sender, msg.value);
        }

        //fire events
        emit SigningProofRequestCreated(id, msg.sender);
    }


    /**
     * @dev Provide a signature for given id with providing the address that should be rewarded. The signature must be done by  
     *      must be done by request creator, otherwise rejected
     * @param id id of the signProof request
     */
    function proofSigningRequest(bytes32 id, address receiver, uint8 v, bytes32 r, bytes32 s ) public returns (bool)
    {
        SignedProofRequest storage request = signingProofRequests[id];

        //request must exists
        require(request.exists == true, "signingproof request with given id not exists");


        //check if receiver has already claimed his reward
        require(!request.claimed[receiver], "receiver already claimed the reward");

        //create hash of receiver address, that was signed outside
        bytes32 hash = keccak256(abi.encodePacked(receiver));

        //receive signer address from signature that also signed the receiver
        address signer = recoverAddress(hash, v,r,s);

        //signature must be done from original request sender
        require(request.creator == signer, "creator must match signing address");

        //check if all claims needed exists and has value other than default
        for(uint i = 0; i < request.claimsNeededSetByCreator.length;i++) {
            bytes32 value = registry.getClaim(signer, receiver, request.claimsNeededSetByCreator[i]);
            require(value != 0, "claim don't exists");
        }
       

        //check if the is a reward modifier claim
        uint rewardAmount = request.reward;   
        if(request.rewardModifierClaim != 0) {
            bytes32 addLevel = registry.getClaim(signer, receiver, request.rewardModifierClaim);
            if(addLevel != 0) {
                uint levelInt = bytesToUInt(addLevel);
                if(request.extraRewardsAmount.length > 0) {
                    rewardAmount = rewardAmount.add(request.extraRewardsAmount[levelInt]);
                }
            }
        }

        //check if balance is sufficient for payout
        require(vault.getBalance(request.creator) >= rewardAmount);

        //make the payout to receiver address and reduce from creator
        vault.subtractBalance(request.creator,rewardAmount);

        //send DAT        
        receiver.send(rewardAmount);

        //set claimed flag to true
        request.claimed[receiver] = true;

        //fire reward event
        emit RewardReceived(id, request.creator, receiver, rewardAmount);

        return true;
        
    }

    /**
     * @dev Provide a signature for given id with providing the address that should be rewarded. The signature must be done by  
     *      must be done by request creator, otherwise rejected
     * @param id id of the signProof request
     */
    function proofSigningRequests(bytes32 id, address[] receiver, uint8[] v, bytes32[] r, bytes32[] s ) public returns (bool[])
    {
        //request must exists
        require(signingProofRequests[id].exists != true, "signingproof request with given id not exists");

        //all array length must have same length
        require(receiver.length == v.length, "arrays must have same length");


        bool[] storage successFlags;

        //iterate trough all entries in array
        for(uint i = 0; i < receiver.length;i++) {
            bool bReturn = proofSigningRequest(id, receiver[i], v[i], r[i], s[i]);
            successFlags.push(bReturn);
        }

        return successFlags;
    }

    /**
     * @dev Cancel data request
     * @param id id of the data request
     */
    function cancelRequest(bytes32 id) public {
        //delete request
        delete dataRequests[msg.sender][id];

        //get deposit for id
        uint256 value = vault.getStorageBalance(msg.sender, id);

        //send tokens
        msg.sender.transfer(value);

        //fire event
        emit DataRequestCancelled(msg.sender, id, value);
    }


   
   /**
     * @dev Add a data item to the marketplace
     * @param id id of the data item
     * @param price min amount must be paid for this item
     * @param duration blocks how long this item is active in marketplace
     */
   function addDataItem(bytes32 id, uint price, bytes32 category, bytes metadata, bytes example,  uint duration, bytes proof) public {
       //create struct
        DataItem memory item = DataItem(msg.sender, id, price, category, metadata, example,  duration,proof, true);

        // add item
        items.push(item);
        uint index = items.length -1;

        //add mapping
        hashToIdMap[id] = index;

        hashes.push(id);

        //add item to msg.sender items
        dataItemsForAddress[msg.sender].push(id);

       //fire event
       emit DataItemAdded(msg.sender, id, price, duration);
   }


   function buyDataItem(bytes32 id) public payable {

       if(msg.value != 0) {
            vault.addBalance(msg.sender, msg.value);

            emit Deposit(msg.sender, msg.value);
       }

       //item must exists
       require(items[hashToIdMap[id]].exists == true);

       //user must have enough balance to buy
       require(vault.getBalance(msg.sender) >= items[hashToIdMap[id]].price);

       //remove buyer balance
       vault.subtractBalance(msg.sender, items[hashToIdMap[id]].price);

       //add owner balance
       vault.addBalance(items[hashToIdMap[id]].owner,  items[hashToIdMap[id]].price);

        //add item to new owner items
        dataItemsForAddress[msg.sender].push(id);

        //fire event
        emit DataItemTraded( items[hashToIdMap[id]].owner, msg.sender,id , items[hashToIdMap[id]].price );

   }


     /**
     * @dev Deposit DATCoins to the martketplace
     */
   function deposit() payable public {
       vault.addBalance(msg.sender, msg.value);

       emit Deposit(msg.sender, msg.value);
   }

    /**
     * @dev Withdraw from virtual martketplace wallet
     * @param amount amount to withdraw
     */
   function withdrawal(uint256 amount) public {

       //check for locked money in auctions, not good solution ,must be changed, to much gas
       bytes32[] memory bids = auctionBidsForUser[msg.sender];
       uint amountInBids = 0;
       for(uint i = 0;i < bids.length;i++)
       {
            bytes32 id = bids[i];
            if(dataAuctions[id].closed) 
            {
                continue;
            }
            for(uint a = 0; a < auctionBids[id].length;a++)
            {
                if(auctionBids[id][a].owner == msg.sender) {
                    amountInBids = amountInBids.add(auctionBids[id][a].amount);
                }
            }
       }

       //must have balance
       require((vault.getBalance(msg.sender) - amountInBids) >= amount);

       //transfer
       msg.sender.transfer(amount);
     
       //fire event
       emit Withdrawal(msg.sender, amount);
   }

   /**
     * @dev Bid on a existing auction
     * @param id id of the auction
     * @param amount amount to bid 
     */
   function bid(bytes32 id, uint256 amount) public {
        //basic checks
        require(msg.sender != 0);

        //get auction with id from mapping
        Auction memory auction = dataAuctions[id];

        //auction must exist...
        require(auction.exists);

        //auction must not be closed
        require(!auction.closed);

        //bid must be equal or higher the minBId
        require(amount >= auction.minBid);

        //next bid must be higher and bidStep
        require(amount > (auction.lastBid + auction.bidStep));

        //user must have deposited min amount;
        require(vault.getBalance(msg.sender) >= amount);

        //auction must be still open
        //require(auction.createdAtBlock + auction.durationBlock <= block.number);

        //add bid
        auctionBids[id].push(Bid(msg.sender, amount, block.number));

        //set last bid
        dataAuctions[id].lastBid = amount;

        //set relation to user
        auctionBidsForUser[msg.sender].push(id);

        //fire event
        emit AuctionBid(id, msg.sender, amount);
   }

    /**
     * @dev Closes an open auction
     * @param id id of the auction
     */
   function closeAuction(bytes32 id) public {
        //get auction with id from mapping
        Auction memory auction = dataAuctions[id];

        //auction must exist...
        require(auction.exists);

        //auction must be msg.sender
        require(auction.owner == msg.sender);

        //auction must be open
        require(!auction.closed);

        //get last bid
        Bid memory lastBid = auctionBids[id][auctionBids[id].length-1];

        //reduce balacnce from buyer
        vault.subtractBalance(lastBid.owner, lastBid.amount);

        //add to auction owner
        vault.addBalance(msg.sender, lastBid.amount);

        //close auction
        dataAuctions[id].closed = true;

        emit AuctionClosed(id, msg.sender,  lastBid.owner, lastBid.amount);

   }

    /**
    * @dev Get all data id's that are for sale
    */
    function getItemIdsForSale() public view returns(bytes32[]) {
        return hashes;
    }


    /**
    * @dev Get all item owned or bought by given address
    */
    function getItemIdsForAddress(address wallet) public view returns (bytes32[]) {
        return dataItemsForAddress[wallet];
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
        uint amount,
        bytes32 category,
        bytes metadata,
        bytes example,
        uint duration,
        bytes proof,
        bool exists) {

      
        uint index = hashToIdMap[dataHash];
        DataItem memory item = items[index];
        return (
        item.owner,
        item.dataHash,
        item.price,
        item.category,
        item.metadata,
        item.example,
        item.duration,
        item.proof,
        item.exists
        );
    }


    /**
    * @dev Recover address from signed message
    */
    function recoverAddress(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address) {
        return ecrecover(hash, v, r, s);
    }

    /// @dev Converts a numeric string to it's unsigned integer representation.
    /// @param v The string to be converted.
    function bytesToUInt(bytes32 v) internal pure returns (uint ret) {
        if (v == 0x0) {
            revert();
        }
        uint digit;
        for (uint i = 0; i < 32; i++) {
            digit = uint((uint(v) / (2 ** (8 * (31 - i)))) & 0xff);
            if (digit == 0) {
                break;
            }
            else if (digit < 48 || digit > 57) {
                revert();
            }
            ret *= 10;
            ret += (digit - 48);
        }
        return ret;
    }
}
