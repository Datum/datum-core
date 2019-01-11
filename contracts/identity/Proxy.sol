pragma solidity ^0.4.23;
import "../shared/Ownable.sol";


contract Proxy is Ownable {
    event Forwarded (address indexed destination, uint value, bytes data);
    event Received (address indexed sender, uint value);

    function () public payable { 
        emit Received(msg.sender, msg.value); 
    }

    function forward(address destination, uint value, bytes data) public onlyOwner {
        require(executeCall(destination, value, data));
        emit Forwarded(destination, value, data);
    }

    // copied from GnosisSafe
    // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
    function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
        assembly {
            success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }
}