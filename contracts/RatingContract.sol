pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';

/**
 * @title Rating contract
 * All parties involved in Datum network can rate each other like on other marketplaces e.g. ebay.
 * The goal is to display in the marketplace the users (Ethereum public address) rating.
 */
contract Rating is Ownable {
    using SafeMath for uint;
    
    // struct for each data item
    struct DataItem {
        bool isItem;
        uint upvotes;
        uint downvotes;
    }
    
    // mapping for votes
    mapping (address => mapping (bytes32 => DataItem)) dataVotes;
    // mapping for voters' vote history
    mapping (address => mapping (bytes32 => bool)) voteHistory;
    // mapping to count total upvotes of a voter
    mapping (address => uint) upvotesForProvider;
    // mapping to count total downvotes of a voter
    mapping (address => uint) downvotesForProvider;
    
    // authorize if msg.sender didn't vote to dataId
    modifier isNewVote(bytes32 dataId) {
        require(voteHistory[msg.sender][dataId] != true);
        _;
    }
    
    constructor () public {
        
    }
    
    /**
     * @dev upvote for item (_provider, _dataId)
     * @param _provider address to clear ratings
     * @param _dataId id of the item
     */
    function rateUp(address _provider, bytes32 _dataId) public isNewVote(_dataId) {
        // (_provider, _dataId) pair is already exists
        if (dataVotes[_provider][_dataId].isItem == true) {
            dataVotes[_provider][_dataId].upvotes += 1;
        } else {
            dataVotes[_provider][_dataId] = DataItem({
                isItem: true,
                upvotes: 1,
                downvotes: 0
            });
        }
        
        // increase count of upvotes for msg.sender
        upvotesForProvider[_provider] += 1;
        // mark this voter as voted for this dataId
        voteHistory[msg.sender][_dataId] = true;
    }
    
    
    /**
     * @dev downvote for item (_provider, _dataId)
     * @param _provider address to clear ratings
     * @param _dataId id of the item
     */
    function rateDown(address _provider, bytes32 _dataId) public isNewVote(_dataId) {
        // (_provider, _dataId) pair is already exists
        if (dataVotes[_provider][_dataId].isItem == true) {
            dataVotes[_provider][_dataId].downvotes += 1;
        } else {
            dataVotes[_provider][_dataId] = DataItem({
                isItem: true,
                upvotes: 0,
                downvotes: 1
            });
        }
        
        // increase count of upvotes for msg.sender
        downvotesForProvider[_provider] += 1;
        // mark this voter as voted for this dataId
        voteHistory[msg.sender][_dataId] = true;
    }
    
    /**
     * @dev return total (upvotes, downvotes) of a provider
     * @param _provider address to clear ratings
     */
    function ratingForAddress(address _provider) public constant returns (uint, uint) {
        return (upvotesForProvider[_provider], downvotesForProvider[_provider]);
    }
    
    /**
     * @dev return (upvotes, downvotes) of a (provider, item)
     * @param _provider address to clear ratings
     * @param _dataId id of the item
     */
    function ratingForAddressWithDataId(address _provider, bytes32 _dataId) public constant returns (uint, uint) {
        if (dataVotes[_provider][_dataId].isItem == true) {
            return (dataVotes[_provider][_dataId].upvotes, dataVotes[_provider][_dataId].downvotes);
        } else {
            return (0, 0);
        }
    }
    
     /**
     * @dev clear upvotes and downvotes for (_provider, _dataId);
     * @param _provider address to clear ratings
     * @param _dataId id of the item
     */
    function clearRating(address _provider, bytes32 _dataId) public onlyOwner {
        if (dataVotes[_provider][_dataId].isItem == true) {
            upvotesForProvider[_provider] = upvotesForProvider[_provider].sub(dataVotes[_provider][_dataId].upvotes);
            dataVotes[_provider][_dataId].upvotes = 0;
            downvotesForProvider[_provider] = downvotesForProvider[_provider].sub(dataVotes[_provider][_dataId].downvotes);
            dataVotes[_provider][_dataId].downvotes = 0;
        }
    }
} 
 