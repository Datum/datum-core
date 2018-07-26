pragma solidity 0.4.23;

import "./MetaIdentityManager.sol";


// This contract is meant as a "singleton" forwarding contract.
// Eventually, it will be able to forward any transaction to
// Any contract that is built to accept it.
contract TxRelay {


    // Note: This is a local nonce.
    // Different from the nonce defined w/in protocol.
    mapping(address => uint) nonce;

    // This mapping specifies a whitelist of allowed senders for transactions.
    // There can be one whitelist per ethereum account, which is the owner of that
    // whitelist. Users can specify which whitelist they want to use when signing
    // a transaction. They can use their own whitelist, a whitelist belonging
    // to another account, or skip using a whitelist by specifying the zero address.
    mapping(address => mapping(address => bool)) public whitelist;

    event Test(address sender);


    /*
     * @dev Relays meta transactions
     * @param sigV, sigR, sigS ECDSA signature on some data to be forwarded
     * @param destination Location the meta-tx should be forwarded to
     * @param data The bytes necessary to call the function in the destination contract.
     * Note: The first encoded argument in data must be address of the signer. This means
     * that all functions called from this relay must take an address as the first parameter.
     */
    function relayMetaTx(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        address destination,
        bytes data,
        address listOwner
    ) public {

        // only allow senders from the whitelist specified by the user,
        require(whitelist[listOwner][msg.sender]);

        //address originalSender = getAddress(data);


        address originalSender = msg.sender;


        emit Test(originalSender);
        // use EIP 191
        // 0x19 :: version :: relay :: whitelistOwner :: nonce :: destination :: data
        bytes32 h = keccak256(byte(0x19), byte(0), this, listOwner, nonce[originalSender], destination, data);
        address addressFromSig = ecrecover(h, sigV, sigR, sigS);


        emit Test(addressFromSig);
      
        //original sender must be the signer of datda
        require(originalSender == addressFromSig);

        //update nonce
        nonce[originalSender]++; //if we are going to do tx, update nonce

        //call identity
        require(destination.call(data));
    }

    /*
     * @dev Gets an address encoded as the first argument in transaction data
     * @param b The byte array that should have an address as first argument
     * @returns a The address retrieved from the array
     (Optimization based on work by tjade273)
     */
    function getAddress(bytes b) public pure returns (address a) {
        if (b.length < 36) return address(0);
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            a := and(mask, mload(add(b, 36)))
            // 36 is the offset of the first parameter of the data, if encoded properly.
            // 32 bytes for the length of the bytes array, and 4 bytes for the function signature.
        }
    }

    /*
     * @dev Returns the local nonce of an account.
     * @param add The address to return the nonce for.
     * @return The specific-to-this-contract nonce of the address provided
     */
    function getNonce(address add) public constant returns (uint) {
        return nonce[add];
    }

    /*
     * @dev Returns flag if msg.sender is in given whiteliste address to use metaTx.
     * @param add The address to return whiteliste allowance for
     * @return The true/false
     */
    function isInWhitelist(address owner) public view returns(bool) {
        return whitelist[owner][msg.sender];
    }

    /*
     * @dev Register for metaTx service
     */
    function register() public {
        whitelist[msg.sender][msg.sender] = true;
    }


    /*
     * @dev Adds a number of addresses to a specific whitelist. Only
     * the owner of a whitelist can add to it.
     * @param sendersToUpdate the addresses to add to the whitelist
     */
    function addToWhitelist(address[] sendersToUpdate) public {
        updateWhitelist(sendersToUpdate, true);
    }

    /*
     * @dev Removes a number of addresses from a specific whitelist. Only
     * the owner of a whitelist can remove from it.
     * @param sendersToUpdate the addresses to add to the whitelist
     */
    function removeFromWhitelist(address[] sendersToUpdate) public {
        updateWhitelist(sendersToUpdate, false);
    }

    /*
     * @dev Internal logic to update a whitelist
     * @param sendersToUpdate the addresses to add to the whitelist
     * @param newStatus whether to add or remove addresses
     */
    function updateWhitelist(address[] sendersToUpdate, bool newStatus) private {
        for (uint i = 0; i < sendersToUpdate.length; i++) {
            whitelist[msg.sender][sendersToUpdate[i]] = newStatus;
        }
    }
}