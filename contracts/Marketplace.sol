pragma solidity ^0.4.18;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './VaultManager.sol';
import './StorageContract.sol';


contract MarketplaceContract is Ownable {
    using SafeMath for uint256;


    bytes32[] public hashes;

    DataItem[] public items;

    VaultManager public vault; //address of vault manager
    StorageNodeContract public storageContract; //address of storage contract

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
     * @dev Add data auction
     * @param duration how long the auction is active in blocks (5 second each block)
     * @param minBid the minimal amount for a bid
     * @param bidStep the minimal step for the next bid
     * @param instatBuyPrice bid to instant buy the item
     */
    function addAuction(bytes32 id, uint256 duration, uint256 minBid, uint256 bidStep, uint256 instatBuyPrice) public returns(bytes32) {
        //create id
        bytes32 auctionId = keccak256(msg.sender, blockhash(block.number));


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
        bytes32 id = keccak256(msg.sender, blockhash(block.number), category,price,duration);

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
}
