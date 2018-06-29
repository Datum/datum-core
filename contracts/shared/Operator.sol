pragma solidity ^0.4.23;

contract Operator {
  address public operator;


  /**
   * @dev The Operator constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    operator = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the operator.
   */
  modifier onlyOperator() {
    require(msg.sender == operator);
    _;
  }


  /**
   * @dev Allows the current operator to transfer control of the contract to a newOperator.
   * @param newOperator The address to transfer ownership to.
   */
  function transferOperator(address newOperator) onlyOperator public {
    if (newOperator != address(0)) {
      operator = newOperator;
    }
  }
}

