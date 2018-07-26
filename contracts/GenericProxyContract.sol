pragma solidity ^0.4.23;

import "./shared/Ownable.sol";
import "./StorageContract.sol";

/**
 * @title StorageProxyContract
 * Contract to act as proxy for storage contract. The user uses always this contract to send his transaction. The msg will be forwared to actual version/implementation
  */
contract GenericProxy is Ownable {

  address private _contract;
   
  constructor(address contract_) public {
    _contract = contract_;
  }

  //event if new version updated
  event Upgraded(address indexed version);

  //get actual version
  function getContract() public view returns (address) {
    return _contract;
  }

  //set new version
  function upgradeTo(address c) public onlyOwner {
    require(_contract != c);
    _contract = c;
    emit Upgraded(c);
  }
 
  //forward the actual version
  function () payable public {
    address _v = getContract();
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