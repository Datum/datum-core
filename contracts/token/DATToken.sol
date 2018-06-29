pragma solidity ^0.4.23;


import "./PausableToken.sol";



/**
 * @title DATToken
 * @dev DAT Token contract
 */
contract DATToken is PausableToken {
  using SafeMath for uint256;

  string public name = "DAT Token";
  string public symbol = "DAT";
  uint public decimals = 18;


  uint256 private constant INITIAL_SUPPLY = 2653841597973271663912484125 wei;


  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
  constructor(address _wallet) public {
    totalSupply = INITIAL_SUPPLY;
    balances[_wallet] = INITIAL_SUPPLY;
  }

  function changeSymbolName(string symbolName) onlyOwner public
  {
      symbol = symbolName;
  }

   function changeName(string symbolName) onlyOwner public
  {
      name = symbolName;
  }
}