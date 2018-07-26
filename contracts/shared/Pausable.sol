pragma solidity ^0.4.23;


import "./Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {


      //admins who can call pause/resume functions
  mapping (address => bool) pausableAdmins;


  constructor() public {
     //make owner as a pausableAdmin
     pausableAdmins[owner] = true;
  }


  event Unpause();
  event Pause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
      require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
      require(paused);
    _;
  }

      modifier onlyPausableAdmins() {
        require(pausableAdmins[msg.sender] == true);
        _;
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }

    /**
   * @dev called by the owner to pause, returns to paused state
   */
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return false;
  }

      /**
     * @dev Add admins who can execute pause/resume function
     */
    function addPausableAdmin(address pausableAdmin) public onlyOwner {
        pausableAdmins[pausableAdmin] = true;
    }

    /**
     * @dev Remove admins who can execute pause/resume function
     */
    function removePausableAdmin(address pausableAdmin) public onlyOwner {
        pausableAdmins[pausableAdmin] = false;
    }


        /**
     * @dev Check status with isPaused param
     */
    function checkStatus() public view  {
        require(!paused, "This version has been deprecated, please upgrade the datum-sdk npm package to the latest version");
    }

    /**
     * @dev Get status with isPaused param
     */
    function getStatus() public view returns (string) {
        if (paused) return "This version has been deprecated, please upgrade the datum-sdk npm package to the latest version";
        else return "Ok";
    }
}