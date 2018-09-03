pragma solidity ^0.4.23;

import "./Ownable.sol";
import "../lib/SafeMath.sol";

contract Administratable is Ownable {
  using SafeMath for uint256;


  mapping (address => bool) public admins;
  
  event AddAdmin(address indexed admin);
  event RemoveAdmin(address indexed admin);
  
  modifier onlyAdmins {
    if (msg.sender != owner && !admins[msg.sender]) revert();
    _;
  }

  function addAdmin(address admin) public onlyOwner {
    admins[admin] = true;
  
    emit AddAdmin(admin);
  }

  function removeAdmin(address admin) public onlyOwner {
    admins[admin] = false;

    emit RemoveAdmin(admin);
  }
}