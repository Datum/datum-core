pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';

contract TypeContract is Ownable {

    //event for adding new types per key
    event TypeAdded(address indexed sender, bytes32 name);

    //mapping to hold all data types per key
    mapping(address => bytes32[]) typesPerKey;


    //add a new data type object
    function addType(bytes32 name) public {
        typesPerKey[msg.sender].push(name);

        emit TypeAdded(msg.sender, name);
    }

     //get datum types (owner fix)
    function getDatumTypes() public view returns(bytes32[]) {
        return typesPerKey[owner];
    }

    //get user defined types
    function getCustomTypes() public view returns(bytes32[]) {
        return typesPerKey[msg.sender];
    }
}   