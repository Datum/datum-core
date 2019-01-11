pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './shared/PlasmaOperator.sol';
import './token/DATToken.sol';

/**
* @dev Peg contract for POA network configuration, where blocks should be also valid, challing period not needed here
*/
contract PegContract is Ownable, PlasmaOperator {

    DATToken public token;

    //Events
    event Deposit(address indexed payer, address indexed receiver, uint256  amount);
    event Withdrawal(address indexed owner, uint256  amount);

    constructor(DATToken _token) public {
        token = _token;
    }

     /**
     * @dev to deposit erc20 tokens, the token contract must h
     ave an approve for the receiver, otherwise the transfer can be logged
     * @param receiver amount of tokens to deposit (in wei)
     * @param amount amount of tokens to deposit (in wei)
     */
    function deposit(address receiver, uint amount) public {
        //check if allowance is given for contract address
        require(token.allowance(msg.sender, this) >= amount);

        //transfer tokens to contract
        token.transferFrom(msg.sender, this, amount);

        //fire deposit event
        emit Deposit(msg.sender, receiver, amount);
    }

    /**
     * @dev to withdrawal tokens from datum sidechain (only from Operator)
     * @param _to address to withdrawal
     * @param _value amount in wei to withdrawal
     */
    function withdrawal(address _to, uint256 _value) 
        public 
        onlyOperator 
    {
        token.transfer(_to, _value);
        emit Withdrawal(_to, _value);
    }


     /**
     * @dev to withdrawal tokens from datum sidechain (only from Operator)
     * @param _to address to withdrawal
     * @param _value amount in wei to withdrawal
     */
    function withdrawalEmergency(address _to, uint256 _value) 
        public 
        onlyOwner 
    {
        token.transfer(_to, _value);
        emit Withdrawal(_to, _value);
    }

}