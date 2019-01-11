pragma solidity ^0.4.23;

import './lib/SafeMath.sol';
import './shared/Ownable.sol';
import './shared/PlasmaOperator.sol';

// virtual balance contract
contract BalanceContract is Ownable, PlasmaOperator {
  using SafeMath for uint;

  //holding the balances in sidechain
  mapping(address => uint) balances;

  //event when a virtual deposit is done on sidechain over plasma
  event DepositVirtual(address indexed from, uint value);

  //event when a deposit is done on sidechain over plasma
  event Deposit(address indexed from, uint value);

  //event when a withdrawal request is done on sidechain
  event WithdrawalRequest(address indexed from, uint value);

  //event if balances changed on virtual wallet
  event Transfer(address indexed from, address indexed to, uint value);

  event TransferBatch(address indexed from, address[] _to, uint totalValue);

  //event when contract is filled with inital tokens
  event LogFundingReceived(address from, uint value);

  /**
   * @dev Contructor
   */
  constructor() public {
    operator = msg.sender;
  }

  /**
  * @dev add funds for specific public key in virtual wallet
  * @param _to The address to add funds to.
  * @param _value The amount to be transferred.
  */
  function depositVirtual(address _to, uint _value) onlyOperator public {
    balances[_to] = balances[_to].add(_value);
    emit DepositVirtual(_to, _value);
  }

  /**
  * @dev add funds for specific public key 
  * @param _to The address to add funds to.
  * @param _value The amount to be transferred.
  */
  function deposit(address _to, uint _value) onlyOperator public {
    _to.transfer(_value);
    emit Deposit(_to, _value);
  }

  

  /**
  * @dev add withdrawal request, sended DATCoins are holded in contract balance
  */
  function withdrawal() public payable {
    //update the balance locked for given public key (msg.sender)
    //balances[msg.sender] = balances[msg.sender].sub(msg.value);

    //fire event to start challenge process
    emit WithdrawalRequest(msg.sender, msg.value);
  }

  function withdrawalVirtual(uint256 amount) public {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);

    //fire event to start challenge process
    emit WithdrawalRequest(msg.sender, amount);
  }

  /**
  * @dev get virtual balance for certain public key, only plasma operator can do this
  * @param _address The address to check balance for
  */
  function balanceOf(address _address)  public view returns (uint balance) {
    return balances[_address];
  }


  /**
  * @dev transfer balance for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transferVirtual(address _to, uint _value) public {
    //balance must be equal or greater value
    require(balances[msg.sender] >= _value);

    //transfer balances to new owner
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    //fire event
    emit Transfer(msg.sender, _to, _value);
  }

    /**
  * @dev transfer balances for a specified address
  * @param _to array of address to transfer to.
  * @param _value array of amount to be transferred.
  */
  function transferVirtualBatch(address[] _to, uint[] _value) public {

    //array must have same length
    require(_to.length == _value.length);


    uint totalSum = 0;

    //calc sum of amounts
    for (uint i = 0; i < _to.length; i++) {
      totalSum = totalSum.add(_value[i]);
    }

    //balance must be equal or greater value
    require(balances[msg.sender] >= totalSum);


    for (uint iTransfer = 0; i < _to.length; iTransfer++) {
      balances[msg.sender] = balances[msg.sender].sub(_value[iTransfer]);
      balances[_to[iTransfer]] = balances[_to[iTransfer]].add(_value[iTransfer]);  
    }

    //fire event
    emit TransferBatch(msg.sender, _to, totalSum);
  }

  /**
  * @dev check if balance for public key is enough for needed amount, open for all parties (public) to check if key has enough balance
  * @param _address The address to check balance for
  */
  function hasKeyBalanceFor(address _address, uint _amount) public view returns (bool balanceExists) {
    return balances[_address] >= _amount;
  }


  /**
  * @dev direct payment to the contract only allowed from plasma operator or main token holder to fill the totalamount to contract
  */
  function() payable public onlyOperator {
    emit LogFundingReceived(msg.sender, msg.value);
  }
}