pragma solidity ^0.4.23;

import './shared/Ownable.sol';

contract GenericBytes32Storage is Ownable {

    mapping(bytes32 => uint) UIntStorage;

    function getUIntValue(bytes32 record) public constant returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) public onlyOwner
    {
        UIntStorage[record] = value;
    }

    mapping(bytes32 => string) StringStorage;

    function getStringValue(bytes32 record) public constant returns (string){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) public onlyOwner
    {
        StringStorage[record] = value;
    }

    mapping(bytes32 => address) AddressStorage;

    function getAddressValue(bytes32 record) public constant returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) public onlyOwner
    {
        AddressStorage[record] = value;
    }

    mapping(bytes32 => bytes) BytesStorage;

    function getBytesValue(bytes32 record) public constant returns (bytes){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes value) public onlyOwner
    {
        BytesStorage[record] = value;
    }

    mapping(bytes32 => bool) BooleanStorage;

    function getBooleanValue(bytes32 record) public constant returns (bool){
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) public onlyOwner
    {
        BooleanStorage[record] = value;
    }
    
    mapping(bytes32 => int) IntStorage;

    function getIntValue(bytes32 record) public constant returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) public onlyOwner
    {
        IntStorage[record] = value;
    }
}