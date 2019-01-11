pragma solidity ^0.4.23;


import "./shared/Administratable.sol";

/**
 * @title ForeverStorage
 * Shared data contract with generic mappings
 * Read access for all write access for other contracts and admins only
 */
contract ForeverStorage is Administratable {

    using SafeMath for uint256;

    mapping(bytes32 => uint256)    private bytes32uIntStorage;
    mapping(bytes32 => string)     private bytes32stringStorage;
    mapping(bytes32 => address)    private bytes32addressStorage;
    mapping(bytes32 => bytes32)    private bytes32bytes32Storage;
    mapping(bytes32 => bool)       private bytes32boolStorage;
    mapping(bytes32 => int256)     private bytes32intStorage;

    mapping(address => uint256)    private addressuIntStorage;
    mapping(address => string)     private addressstringStorage;
    mapping(address => address)    private addressaddressStorage;
    mapping(address => bytes32)    private addressbytes32Storage;
    mapping(address => bool)       private addressboolStorage;
    mapping(address => int256)     private addressintStorage;


    //array mappings
    mapping(address => bytes32[])    private addressbytes32ArrayStorage;
    mapping(bytes32 => address[])    private bytes32addressArrayStorage;
    mapping(bytes32 => bytes32[])    private bytes32bytes32ArrayStorage;


    /* GET */

    /// @param _key The key for the record
    function getAddressByBytes32(bytes32 _key) public view returns (address) {
        return bytes32addressStorage[_key];
    }

    /// @param _key The key for the record
    function getAddressesByBytes32(bytes32 _key) public view returns (address[]) {
        return bytes32addressArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32ArrayByBytes32(bytes32 _key) public view returns (bytes32[]) {
        return bytes32bytes32ArrayStorage[_key];
    }


    /// @param _key The key for the record
    function getUintByBytes32(bytes32 _key) public view returns (uint) {
        return bytes32uIntStorage[_key];
    }

    /// @param _key The key for the record
    function getStringByBytes32(bytes32 _key) public view returns (string) {
        return bytes32stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32ByBytes32(bytes32 _key) public view returns (bytes32) {
        return bytes32bytes32Storage[_key];
    }

    /// @param _key The key for the record
    function getBoolByBytes32(bytes32 _key) public view returns (bool) {
        return bytes32boolStorage[_key];
    }

    /// @param _key The key for the record
    function getIntByBytes32(bytes32 _key) public view returns (int) {
        return bytes32intStorage[_key];
    }



    /* SET */

    /// @param _key The key for the record
    function setAddressByBytes32(bytes32 _key, address _value) onlyAdmins external {
        bytes32addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setUintByBytes32(bytes32 _key, uint _value) onlyAdmins external {
        bytes32uIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setStringByBytes32(bytes32 _key, string _value) onlyAdmins external {
        bytes32stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBytes32ByBytes32(bytes32 _key, bytes32 _value) onlyAdmins external {
        bytes32bytes32Storage[_key] = _value;
    }
    
    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBoolByBytes32(bytes32 _key, bool _value) onlyAdmins external {
        bytes32boolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    /// @param _value The value for the record
    function setIntByBytes32(bytes32 _key, int _value) onlyAdmins external {
        bytes32intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setAddressArrayByBytes32(bytes32 _key, address _value) onlyAdmins external {
        bytes32addressArrayStorage[_key].push(_value);
    }

    /// @param _key The key for the record
    /// @param _value The value for the record
    function setBytes32ArrayByBytes32(bytes32 _key, bytes32 _value) onlyAdmins external {
        bytes32bytes32ArrayStorage[_key].push(_value);
    }



    /* DELETE */

    
    /// @param _key The key for the record
    function deleteAddressByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteAllAddressesFromArrayByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32addressArrayStorage[_key];
    }

    
    /// @param _key The key for the record
    /// @param _value The value for the record
    function deleteAddressFromArrayByBytes32(bytes32 _key, address _value) onlyAdmins external {
        address[] storage prfs = bytes32addressArrayStorage[_key];

        uint i = 0;
        while (prfs[i] != _value) {
            i++;
        }


        prfs[i] = prfs[prfs.length-1];
        prfs.length--;

/*
        while (i<prfs.length-1) {
            prfs[i] = prfs[i+1];
            i++;
        }
        prfs.length--;
        */
    }
    

    /// @param _key The key for the record
    /// @param _value The value for the record
    function deleteBytes32FromArrayByBytes32(bytes32 _key, bytes32 _value) onlyAdmins external {
       bytes32[] storage prfs = bytes32bytes32ArrayStorage[_key];

        uint i = 0;

        //get index
        while (prfs[i] != _value) {
            i++;
        }


        prfs[i] = prfs[prfs.length-1];
        prfs.length--;

/*
        while (i<prfs.length-1) {
            prfs[i] = prfs[i+1];
            i++;
        }
        prfs.length--;
        */
    }

    /// @param _key The key for the record
    function deleteUintByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32uIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteStringByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32ByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32bytes32Storage[_key];
    }
    
    /// @param _key The key for the record
    function deleteBoolByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32boolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteIntByBytes32(bytes32 _key) onlyAdmins external {
        delete bytes32intStorage[_key];
    }




    /* METHOD FOR ADDRESS AS KEY */

    /* GET BY ADDRESS */

    
    /// @param _key The key for the record
    function getAddressByAddress(address _key) public view returns (address) {
        return addressaddressStorage[_key];
    }

    function getBytes32ByAddress(address _key) public view returns (bytes32[]) {
        return addressbytes32ArrayStorage[_key];
    }

    /// @param _key The key for the record
    function getUintByAddress(address _key) public view returns (uint) {
        return addressuIntStorage[_key];
    }

    /// @param _key The key for the record
    function getStringByAddress(address _key) public view returns (string) {
        return addressstringStorage[_key];
    }


    /// @param _key The key for the record
    function getBoolByAddress(address _key) public view returns (bool) {
        return addressboolStorage[_key];
    }

    /// @param _key The key for the record
    function getIntByAddress(address _key) public view returns (int) {
        return addressintStorage[_key];
    }


   /* SET BY ADDRESS */

    /// @param _key The key for the record
    function setAddressByAddress(address _key, address _value) onlyAdmins external {
        addressaddressStorage[_key] = _value;
    }

    function setBytes32ArrayByAddress(address _key, bytes32 _value) onlyAdmins external {
        addressbytes32ArrayStorage[_key].push(_value);
    }

    /// @param _key The key for the record
    function setUintByAddress(address _key, uint _value) onlyAdmins external {
        addressuIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setStringByAddress(address _key, string _value) onlyAdmins external {
        addressstringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytesByAddress(address _key, bytes32 _value) onlyAdmins external {
        addressbytes32Storage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setBoolByAddress(address _key, bool _value) onlyAdmins external {
        addressboolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setIntByAddress(address _key, int _value) onlyAdmins external {
        addressintStorage[_key] = _value;
    }


    /* DELETE */

    /// @param _key The key for the record
    function deleteAddressByAddress(address _key) onlyAdmins external {
        delete addressaddressStorage[_key];
    }

    function deleteAllBytes32ByAddress(address _key) onlyAdmins external {
      delete addressbytes32ArrayStorage[_key];
    }

    function deleteBytes32FromArrayByAddress(address _key, bytes32 _value) onlyAdmins external {
        bytes32[] storage prfs = addressbytes32ArrayStorage[_key];

        uint i = 0;
        while (prfs[i] != _value) {
            i++;
        }


        prfs[i] = prfs[prfs.length-1];
        prfs.length--;

        /*
        while (i<prfs.length-1) {
            prfs[i] = prfs[i+1];
            i++;
        }
        prfs.length--;
        */
    }

    /// @param _key The key for the record
    function deleteUintByAddress(address _key) onlyAdmins external {
        delete addressuIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteStringByAddress(address _key) onlyAdmins external {
        delete addressstringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBoolByAddress(address _key) onlyAdmins external {
        delete addressboolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteIntByAddress(address _key) onlyAdmins external {
        delete addressintStorage[_key];
    }

}