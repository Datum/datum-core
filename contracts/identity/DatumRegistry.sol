pragma solidity ^0.4.23;

/**
 * @title Datum Registry Contract
 * All parties involved in Datum network have a Datum Identity based on uPort. They hold a dictionary of claims that can be added and removed
  */
contract DatumRegistry{
  
    mapping(address => mapping(address => mapping(bytes32 => bytes32))) public registry;
    mapping(address => mapping(address => mapping(bytes32 => address))) public registrySigner;

    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt);

    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt);




    /// @dev Create or update a claim
    /// @param subject The address the claim is being issued to
    /// @param key The key used to identify the claim
    /// @param value The data associated with the claim
    function setClaim(address subject, bytes32 key, bytes32 value, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public {
        address signer = recoverAddr(msgHash, v, r,s);
        registry[msg.sender][subject][key] = value;
        registrySigner[msg.sender][subject][key] = signer;
        emit ClaimSet(msg.sender, subject, key, value, now);
    }

    /// @dev Create or update a claim about yourself
    /// @param key The key used to identify the claim
    /// @param value The data associated with the claim
    function setSelfClaim(bytes32 key, bytes32 value, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public {
        setClaim(msg.sender, key, value,msgHash, v,r,s);
    }


    /// @dev Allows to retrieve claims from other contracts as well as other off-chain interfaces
    /// @param issuer The address of the issuer of the claim
    /// @param subject The address to which the claim was issued to
    /// @param key The key used to identify the claim
    function getClaim(address issuer, address subject, bytes32 key) public constant returns(bytes32) {
        return registry[issuer][subject][key];
    }

    /// @dev Verifiy a claim that the issuer has also signed the claim
    /// @param issuer The address of the issuer of the claim
    /// @param subject The address to which the claim was issued to
    /// @param key The key used to identify the claim
    function verifyClaim(address issuer, address subject, bytes32 key) public constant returns (bool) {
        return registrySigner[issuer][subject][key] == issuer;
    }

    function getSigner(address issuer, address subject, bytes32 key) public constant returns(address) {
        return registrySigner[issuer][subject][key];
    }


    /// @dev Allows to remove a claims from the registry.
    ///      This can only be done by the issuer or the subject of the claim.
    /// @param issuer The address of the issuer of the claim
    /// @param subject The address to which the claim was issued to
    /// @param key The key used to identify the claim
    function removeClaim(address issuer, address subject, bytes32 key) public {
        require(msg.sender == issuer || msg.sender == subject);
        require(registry[issuer][subject][key] != 0);
        delete registry[issuer][subject][key];
        emit ClaimRemoved(msg.sender, subject, key, now);
    }


    function recoverAddr(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }
}