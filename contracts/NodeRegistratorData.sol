pragma solidity ^0.4.24;

import './ForeverStorage.sol';
import "./shared/Administratable.sol";
import "./StorageKeys.sol";
import './lib/Strings.sol';

contract NodeRegistratorData is Administratable {

    using Strings for *;

    ForeverStorage public foreverStorage; //storage contract
    StorageKeys private storageKeys;

    constructor(address _forever, address _storageKeys) public {
        foreverStorage = ForeverStorage(_forever);
        storageKeys = StorageKeys(_storageKeys);
    }

    function setStorage(address _foreverStorage) public onlyOwner {
        foreverStorage = ForeverStorage(_foreverStorage);
    }

    function nodeExists(address node) public view returns(bool) {
        return foreverStorage.getBoolByBytes32(storageKeys.KeyNodeExists(node));
    }

    function getNodeCount() public view returns(uint) {
        return foreverStorage.getAddressesByBytes32(storageKeys.KeyNodeList()).length +
            foreverStorage.getAddressesByBytes32(storageKeys.KeyDatumNodeList()).length;
    }

    function setNodeMode(address node, bool bOnline) public onlyAdmins {
        foreverStorage.setBoolByBytes32(storageKeys.KeyNodeOnline(node), bOnline);
    }

    function getNodes() public view returns (address[]) {
        return foreverStorage.getAddressesByBytes32(storageKeys.KeyNodeList());
    }

    function getDatumNodes() public view returns (address[]) {
        return foreverStorage.getAddressesByBytes32(storageKeys.KeyDatumNodeList());
    }

    function startUnregister(address node) public onlyAdmins {
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeUnregisterStart(node), now);
        foreverStorage.setStringByBytes32(storageKeys.KeyNodeStatus(node), "unregister");
    }

    function getStartUnregisterDate(address node) public view returns(uint) {
        return foreverStorage.getUintByBytes32(storageKeys.KeyNodeUnregisterStart(node));
    }

    function set(address nodeAddress,string endpoint, uint region, uint bandwidth) public onlyAdmins {
        bool isDatumNode = isEndpointDatumNode(endpoint);

        foreverStorage.setStringByBytes32(storageKeys.KeyNodeEndpoint(nodeAddress), endpoint);
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeRegion(nodeAddress), region);
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeBandwidth(nodeAddress), bandwidth);
        foreverStorage.setStringByBytes32(storageKeys.KeyNodeStatus(nodeAddress), "active");
        foreverStorage.setBoolByBytes32(storageKeys.KeyNodeExists(nodeAddress), true);
        foreverStorage.setBoolByBytes32(storageKeys.KeyNodeDatum(nodeAddress), isDatumNode);

        if(isDatumNode) {
            foreverStorage.setAddressArrayByBytes32(storageKeys.KeyDatumNodeList(), nodeAddress);
        } else {
            foreverStorage.setAddressArrayByBytes32(storageKeys.KeyNodeList(), nodeAddress);
        }
    }

    function remove(address nodeAddress) public onlyAdmins {

        bool isDatumNode = foreverStorage.getBoolByBytes32(storageKeys.KeyNodeDatum(nodeAddress));

        if(isDatumNode) {
            foreverStorage.deleteAddressFromArrayByBytes32(storageKeys.KeyDatumNodeList(), nodeAddress);
        } else {
            foreverStorage.deleteAddressFromArrayByBytes32(storageKeys.KeyNodeList(), nodeAddress);
        }

        foreverStorage.deleteBoolByBytes32(storageKeys.KeyNodeExists(nodeAddress));
        

        //delete infos
        foreverStorage.deleteStringByBytes32(storageKeys.KeyNodeEndpoint(nodeAddress));
        foreverStorage.deleteUintByBytes32(storageKeys.KeyNodeRegion(nodeAddress));
        foreverStorage.deleteUintByBytes32(storageKeys.KeyNodeBandwidth(nodeAddress));
        foreverStorage.deleteStringByBytes32(storageKeys.KeyNodeStatus(nodeAddress));
        foreverStorage.setBoolByBytes32(storageKeys.KeyNodeExists(nodeAddress), false);
    }

    function update(address nodeAddress, string endpoint, uint256 bandwidth, uint256 region) public onlyAdmins {
        bool isDatumNode = isEndpointDatumNode(endpoint);
        bool isRegisteredAsDatumNode = foreverStorage.getBoolByBytes32(storageKeys.KeyNodeDatum(nodeAddress));

        //node change from datum -> non-datum vis-versa..
        if(isRegisteredAsDatumNode != isDatumNode) {
            //was datum node, now non-datum
            if(isRegisteredAsDatumNode) {
                //remove from datum node
                foreverStorage.deleteAddressFromArrayByBytes32(storageKeys.KeyDatumNodeList(), nodeAddress);

                //add as normal node
                foreverStorage.setAddressArrayByBytes32(storageKeys.KeyNodeList(), nodeAddress);
            } else {
                //was non-datum node, now datum
                foreverStorage.deleteAddressFromArrayByBytes32(storageKeys.KeyNodeList(), nodeAddress);

                //add as datum node
                foreverStorage.setAddressArrayByBytes32(storageKeys.KeyDatumNodeList(), nodeAddress);
            }
        }


        foreverStorage.setStringByBytes32(storageKeys.KeyNodeEndpoint(nodeAddress), endpoint);
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeRegion(nodeAddress), region);
        foreverStorage.setUintByBytes32(storageKeys.KeyNodeBandwidth(nodeAddress), bandwidth);
        foreverStorage.setBoolByBytes32(storageKeys.KeyNodeDatum(nodeAddress), isDatumNode);
    }

    function removeProof(address nodeAddress, bytes32 dataHash) public onlyAdmins {
        foreverStorage.deleteUintByBytes32(storageKeys.KeyNodeProofRequestTime(nodeAddress, dataHash));
        foreverStorage.deleteAllAddressesFromArrayByBytes32(storageKeys.KeyNodeProofRequestCreator(nodeAddress, dataHash));
        foreverStorage.deleteUintByBytes32(storageKeys.KeyNodeProofChunkRequested(nodeAddress, dataHash));
        foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyNodeProofRequestsForAddress(nodeAddress), dataHash);
    }

    //works only with pure domain name and port , dont include http/https at beginning!
    function isEndpointDatumNode(string endpoint) public pure returns (bool) {
        bool isDatumNode = false;
        Strings.slice memory s = endpoint.toSlice();
        var delim = ":".toSlice();
        var parts = new string[](s.count(delim) + 1);

        for(uint i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }

        if(parts[0].toSlice().endsWith(".datum.org".toSlice())) {
            isDatumNode = true;
        } 

        return isDatumNode;
    }


    //return the max storage amount in bytes for given balance
    function getMaxStorageAmount(uint balance) public pure returns(uint) {
        //formula from defintion =0.04608436*POWER(A34,0.4992941)
        return nthRoot((balance / 1000000000000000000), 2, 8) * 4608436 / 10000000;
    }


    //get actual amount stored by this node in bytes
    function getSizeStoredByNode(address nodeAddress) public view returns(uint256) {
        return foreverStorage.getUintByBytes32(storageKeys.KeySizeForNode(nodeAddress));
    }

    //calculate nth root of a with n, dp is decimal holded, do 10 iterations
    function nthRoot(uint _a, uint _n, uint _dp) public pure returns(uint) {
        assert (_n > 1);
        uint one = 10 ** (1 + _dp);
        uint a0 = one ** _n * _a;
        uint xNew = one;
        uint iter = 0;
        while (xNew != x && iter < 10) {
            uint x = xNew;
            uint t0 = x ** (_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;
            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
        }
        return (xNew + 5) / 10;
    }

    function getMerkleRoot(bytes32 dataHash) public view returns(bytes32) {
        return foreverStorage.getBytes32ByBytes32(storageKeys.KeyItemMerkle(dataHash));
    }

    function setVerifiedProof(address node, bytes32 dataHash, bool verified) public onlyAdmins {
        foreverStorage.setBoolByBytes32(storageKeys.KeyNodeProofSnarksVerified(node, dataHash), verified);
    }

    function getVerifiedProof(address node, bytes32 dataHash) public view returns(bool) {
        return foreverStorage.getBoolByBytes32(storageKeys.KeyNodeProofSnarksVerified(node, dataHash));
    }

    function getProofs(address node) public view returns(bytes32[]) {
        return foreverStorage.getBytes32ArrayByBytes32(storageKeys.KeyNodeProofRequestsForAddress(node));
    }

    function getProofRequestTime(address node, bytes32 dataHash) public view returns(uint) {
        return foreverStorage.getUintByBytes32(storageKeys.KeyNodeProofRequestTime(node, dataHash));
    }

    function getProofWorkstatus(address node, bytes32 dataHash) public view returns(bool) {
        return foreverStorage.getBoolByBytes32(storageKeys.KeyNodeProofWorkStatus(node, dataHash));
    }

    function getItemsForNode(address node) public view returns(bytes32[]) {
        return foreverStorage.getBytes32ArrayByBytes32(storageKeys.KeyItemsForNode(node));
    }

    function getItemCreated(bytes32 dataHash) public view returns(uint) {
        return foreverStorage.getUintByBytes32(storageKeys.KeyItemCreated(dataHash));
    }

    function getItemLastPaid(bytes32 dataHash, address node) public view returns(uint) {
        return foreverStorage.getUintByBytes32(storageKeys.KeyItemLastPaid(dataHash,node));
    }

    function setItemLastPaid(bytes32 dataHash, address node) public onlyAdmins {
        foreverStorage.setUintByBytes32(storageKeys.KeyItemLastPaid(dataHash, node), now); 
    }

    function getItemSize(bytes32 dataHash) public view returns(uint) {
        return foreverStorage.getUintByBytes32(storageKeys.KeyItemSize(dataHash));
    }

    function getItemCreator(bytes32 dataHash) public view returns(address) {
        return foreverStorage.getAddressByBytes32(storageKeys.KeyItemCreator(dataHash));
    }


    function isAddressDatumNode(address nodeAddress) public view returns(bool) {
        return isEndpointDatumNode(foreverStorage.getStringByBytes32(storageKeys.KeyNodeEndpoint(nodeAddress)));
    }

    function getNodeInfo(address node)
    public
    view
    returns (
        string endpoint,
        uint bandwidth,
        uint region,
        string status,
        bool online,
        bool datumNode) {

        return (
        foreverStorage.getStringByBytes32(storageKeys.KeyNodeEndpoint(node)),
        foreverStorage.getUintByBytes32(storageKeys.KeyNodeBandwidth(node)),
        foreverStorage.getUintByBytes32(storageKeys.KeyNodeRegion(node)),
        foreverStorage.getStringByBytes32(storageKeys.KeyNodeStatus(node)),
        foreverStorage.getBoolByBytes32(storageKeys.KeyNodeOnline(node)),
        foreverStorage.getBoolByBytes32(storageKeys.KeyNodeDatum(node)));

    } 
}