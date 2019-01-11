pragma solidity ^0.4.23;

import './shared/PlasmaOperator.sol';
import './lib/SafeMath.sol';

/**
* @dev Balance contract in 
*/
contract DatumPlasmaPOA is PlasmaOperator {
  using SafeMath for uint256;

  address public migrator;
  uint256 public migratorAviableAmount = 0;

  //event when a deposit is done on sidechain over plasma
  event Deposit(address indexed from, uint value);

  //event when a withdrawal request is done on sidechain
  event WithdrawalRequest(address indexed from, address indexed to,  uint value);

  //event when contract was filled with initial funding of all tokens
  event LogFundingReceived(address indexed from, uint value);

  event MigratorSet(address indexed sender, uint maxValue);

  //migration mapping
  mapping(address => bool) public migrationProcessed;

  //deposits processed
  mapping(address => mapping(bytes32 => uint256)) public depositsProcessed;


  /**
   * @dev Contructor
   */
  constructor() public {
    
  }


  /**
  * @dev set migrator address and maxAmount to he can release 
  * @param _migrator The address of the migrator
  * @param _maxAmount The amount to be max transferred.
  */
  function setMigrationAddress(address _migrator, uint256 _maxAmount) onlyOperator public {
      migrator =_migrator; 
      migratorAviableAmount = _maxAmount;

      emit MigratorSet(migrator, migratorAviableAmount);
  }

  /**
  * @dev add funds for specific public key 
  * @param _to The address to add funds to.
  * @param _value The amount to be transferred.
  */
  function deposit(address _to, uint _value, bytes32 txHash) onlyOperator public {
    //check the receiver is not 0
    require(_to != 0);

    //check if txHash for given address already processed
    require(depositsProcessed[_to][txHash] == 0, "already processed txHash for given address");

    //send amount
    _to.transfer(_value);

    //set processed with amount
    depositsProcessed[_to][txHash] = _value;

    //fire event
    emit Deposit(_to, _value);
  }

  /**
  * @dev add withdrawal request, sended DATCoins are holded in contract balance, anyone can call this method
  */
  function withdrawal(address _to) public payable {
    require(_to != 0);
    //fire event to start challenge process
    emit WithdrawalRequest(msg.sender, _to, msg.value);
  }

  /**
  * @dev used to migrate funds, can be only called by migrator
  */
  function migrateFunds(address _to, uint256 _value) public {
    //check if msg.sender is migrator set
    require(msg.sender == migrator, "only set migrator is allowed to call this method");

    //check if migration already done for this identity
    require(!migrationProcessed[_to], "migration already done for this address");

    //check if migrator has enough balance allowed to send
    require(migratorAviableAmount >= _value, "migrator balance exceeded!");

    //send tokens
    _to.transfer(_value);

    //set processed flag
    migrationProcessed[_to] = true;

    //reduce migrator amount
    migratorAviableAmount = migratorAviableAmount.sub(_value);

    //fire event
    emit Deposit(_to, _value);
  }

  /**
  * @dev direct payment to the contract only allowed from plasma operator or main token holder to fill the totalamount to contract
  */
  function() payable public onlyOperator {
    emit LogFundingReceived(msg.sender, msg.value);
  }
}