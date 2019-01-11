pragma solidity ^0.4.23;
import "./Proxy.sol";

/**
 * @title Datum Identity Manager
 * All parties involved in Datum network have a Datum Identity based on uPort.
  */
contract MetaIdentityManager {
    uint adminTimeLock;
    uint userTimeLock;
    uint adminRate;
    address relay;

    event LogIdentityCreated(
        address indexed identity,
        address indexed creator,
        address owner,
        address indexed recoveryKey);

    event LogOwnerAdded(
        address indexed identity,
        address indexed owner,
        address instigator);

    event LogOwnerRemoved(
        address indexed identity,
        address indexed owner,
        address instigator);

    event LogRecoveryChanged(
        address indexed identity,
        address indexed recoveryKey,
        address instigator);


    mapping(address => mapping(address => uint)) owners;
    mapping(address => address) recoveryKeys;
    mapping(address => mapping(address => uint)) limiter;
    

    modifier onlyAuthorized() {
        require(msg.sender == relay || checkMessageData(msg.sender));
        _;
    }

    modifier onlyOwner(address identity, address sender) {
        require(isOwner(identity, sender));
        _;
    }

    modifier onlyOlderOwner(address identity, address sender) {
        require(isOlderOwner(identity, sender));
        _;
    }

    modifier onlyRecovery(address identity, address sender) {
        require(recoveryKeys[identity] == sender);
        _;
    }

    modifier rateLimited(Proxy identity, address sender) {
        require(limiter[identity][sender] < (now - adminRate));
        limiter[identity][sender] = now;
        _;
    }

    modifier validAddress(address addr) { //protects against some weird attacks
        require(addr != address(0));
        _;
    }

    /// @dev Contract constructor sets initial timelocks and meta-tx relay address
    /// @param _userTimeLock Time before new owner added by recovery can control proxy
    /// @param _adminTimeLock Time before new owner can add/remove owners
    /// @param _adminRate Time period used for rate limiting a given key for admin functionality
    /// @param _relayAddress Address of meta transaction relay contract
    constructor(uint _userTimeLock, uint _adminTimeLock, uint _adminRate, address _relayAddress) public {
        require(_adminTimeLock >= _userTimeLock);
        adminTimeLock = _adminTimeLock;
        userTimeLock = _userTimeLock;
        adminRate = _adminRate;
        relay = _relayAddress;
    }

    /// @dev Creates a new proxy contract for an owner and recovery
    /// @param owner Key who can use this contract to control proxy. Given full power
    /// @param recoveryKey Key of recovery network or address from seed to recovery proxy
    /// Gas cost of ~300,000
    function createIdentity(address owner, address recoveryKey) public validAddress(recoveryKey) {
        Proxy identity = new Proxy();
        owners[identity][owner] = now - adminTimeLock; // This is to ensure original owner has full power from day one
        recoveryKeys[identity] = recoveryKey;
        emit LogIdentityCreated(identity, msg.sender, owner,  recoveryKey);
    }

    /// @dev Creates a new proxy contract for an owner and recovery and allows an initial forward call which would be to set the registry in our case
    /// @param owner Key who can use this contract to control proxy. Given full power
    /// @param recoveryKey Key of recovery network or address from seed to recovery proxy
    /// @param destination Address of contract to be called after proxy is created
    /// @param data of function to be called at the destination contract
    function createIdentityWithCall(address owner, address recoveryKey, address destination, bytes data) public validAddress(recoveryKey) {
        Proxy identity = new Proxy();
        owners[identity][owner] = now - adminTimeLock; // This is to ensure original owner has full power from day one
        recoveryKeys[identity] = recoveryKey;
        emit LogIdentityCreated(identity, msg.sender, owner,  recoveryKey);
        identity.forward(destination, 0, data);
    }

    /// @dev Allows a user to transfer control of existing proxy to this contract. Must come through proxy
    /// @param owner Key who can use this contract to control proxy. Given full power
    /// @param recoveryKey Key of recovery network or address from seed to recovery proxy
    /// Note: User must change owner of proxy to this contract after calling this
    function registerIdentity(address owner, address recoveryKey) public validAddress(recoveryKey) {
        require(recoveryKeys[msg.sender] == 0); // Deny any funny business
        owners[msg.sender][owner] = now - adminTimeLock; // Owner has full power from day one
        recoveryKeys[msg.sender] = recoveryKey;
        emit LogIdentityCreated(msg.sender, msg.sender, owner, recoveryKey);
    }

    /// @dev Allows a user to forward a call through their proxy from relay
    function forwardTo(address sender, Proxy identity, address destination, uint value, bytes data) public
        onlyAuthorized
        onlyOwner(identity, sender)
    {
        identity.forward(destination, value, data);
    }


    /// @dev Allows direct forward from owner
    function forward(Proxy identity, address destination, uint value, bytes data) public
        onlyOwner(identity, msg.sender)
    {
        identity.forward(destination, value, data);
    }


    /// @dev Allows an olderOwner to add a new owner instantly
    function addOwner(address sender, Proxy identity, address newOwner) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
        rateLimited(identity, sender)
    {
        require(!isOwner(identity, newOwner));
        owners[identity][newOwner] = now - userTimeLock;
        emit LogOwnerAdded(identity, newOwner, sender);
    }

    /// @dev Allows a recoveryKey to add a new owner with userTimeLock waiting time
    function addOwnerFromRecovery(address sender, Proxy identity, address newOwner) public
        onlyAuthorized
        onlyRecovery(identity, sender)
        rateLimited(identity, sender)
    {
        require(!isOwner(identity, newOwner));
        owners[identity][newOwner] = now;
        emit LogOwnerAdded(identity, newOwner, sender);
    }

    /// @dev Allows an owner to remove another owner instantly
    function removeOwner(address sender, Proxy identity, address owner) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
        rateLimited(identity, sender)
    {
        // an owner should not be allowed to remove itself
        require(sender != owner);
        delete owners[identity][owner];
        emit LogOwnerRemoved(identity, owner, sender);
    }

    /// @dev Allows an owner to change the recoveryKey instantly
    function changeRecovery(address sender, Proxy identity, address recoveryKey) public
        onlyAuthorized
        onlyOlderOwner(identity, sender)
        rateLimited(identity, sender)
        validAddress(recoveryKey)
    {
        recoveryKeys[identity] = recoveryKey;
        emit LogRecoveryChanged(identity, recoveryKey, sender);
    }


    //Checks that address a is the first input in msg.data.
    //Has very minimal gas overhead.
    function checkMessageData(address a) internal pure returns (bool t) {
        if (msg.data.length < 36) return false;
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            t := eq(a, and(mask, calldataload(4)))
        }
    }

    function isOwner(address identity, address owner) public constant returns (bool) {
        return (owners[identity][owner] > 0 && (owners[identity][owner] + userTimeLock) <= now);
    }

    function isOlderOwner(address identity, address owner) public constant returns (bool) {
        return (owners[identity][owner] > 0 && (owners[identity][owner] + adminTimeLock) <= now);
    }

    function isRecovery(address identity, address recoveryKey) public constant returns (bool) {
        return recoveryKeys[identity] == recoveryKey;
    }
}