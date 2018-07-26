pragma solidity ^0.4.23;

import "./shared/Ownable.sol";
import "./StorageContract.sol";

/**
 * @title StorageProxyContract
 * Contract to act as proxy for storage contract. The user uses always this contract to send his transaction. The msg will be forwared to actual version/implementation
  */
contract StorageProxyContract is Ownable {

  StorageNodeContract private _storage;
   
  constructor(address storage_) public {
    _storage = StorageNodeContract(storage_);
  }

  //event if new version updated
  event Upgraded(address indexed version);

  address public _version;

  //get actual version
  function version() public view returns (address) {
    return _version;
  }

  //set new version
  function upgradeTo(address v) public onlyOwner {
    require(_version != v);
    _version = v;
    emit Upgraded(v);
  }
 
  //forward the actual version
  function () payable public {
    address _v = version();
    require(_v != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, _v, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}