pragma solidity ^0.4.23;

/**
 * @title Datum Registry Contract
 * All parties involved in Datum network have a Datum Identity inspired based UUID implementation, they hold a dictionary of claims that can be added and removed
  */
contract DatumRegistry{
  uint public version;
  mapping(bytes32 => mapping(address => mapping(address => bytes32))) public registry;

  constructor() public {
    version = 1;
  }

  event Set(bytes32 indexed registrationIdentifier, address indexed issuer, address indexed subject, uint updatedAt);

  /**
  * @dev Add to datum registry with subject and value
  * @param registrationIdentifier registration identifier
  * @param subject subject to add
  * @param value value to add to registry
  */
  function set(bytes32 registrationIdentifier, address subject, bytes32 value) public {
      emit Set(registrationIdentifier, msg.sender, subject, now);
      registry[registrationIdentifier][msg.sender][subject] = value;
  }

  /**
  * @dev Get a value from datum registry
  * @param registrationIdentifier registration identifier
  * @param issuer issues of the claim/value
  * @param subject subject that is requested
  */
  function get(bytes32 registrationIdentifier, address issuer, address subject) public constant returns(bytes32){
      return registry[registrationIdentifier][issuer][subject];
  }
}