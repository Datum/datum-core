pragma solidity ^0.4.23;

contract StorageKeys {
    function KeyItemCreated(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemCreated"));
    }

    function KeyItemCreator(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemCreator"));
    }

    function KeyItemCount() public pure returns(bytes32) {
            return keccak256(
            abi.encodePacked("StorageItemCount"));
    }

    function KeyItemOwner(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemOwner"));
    }

    function KeyItemHash(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemHash"));
    }

     function KeyItemMerkle(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemMerkleRoot"));
    }

     function KeyItemSize(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemSize"));
    }

    function KeyItemKey(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemKey"));
    }

    function KeyItemReplication(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemReplicationMode"));
    }

    function KeyItemTrusted(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemTrusted"));
    }

    function KeyItemDeleted(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageItemDeleted"));
    }

    function KeyItemForAddress(address owner) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(owner, "StorageItemsForAddress"));
    }

    function KeyItemForKey(address owner, bytes32 key) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(owner, key, "StorageItemsForKey"));
    }

    function KeyNodesForItem(bytes32 dataHash) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(dataHash, "StorageNodesForItem"));
    }

    function KeyItemLastPaid(bytes32 dataHash, address node) public pure returns (bytes32) {
         return keccak256(
            abi.encodePacked(node, dataHash, "StorageItemLastPaid"));
    }


   function KeyNodeExists(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "NodeExists"));
   }

   function KeyNodeEndpoint(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "NodeEndPoint"));
   }

   function KeyNodeRegion(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "NodeRegion"));
   }

   function KeyNodeBandwidth(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "NodeBandwidth"));
   }

   function KeyNodeStatus(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "NodeStatus"));
   }

   function KeyNodeList() public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked("NodeList"));
   }

   function KeyDatumNodeList() public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked("DatumNodeList"));
   }

   function KeyItemsForNode(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "ItemsForNode"));
   }

   function KeySizeForNode(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "SizeForNode"));
   }

   

   function KeyNodeOnline(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node,"NodeOnline"));
   }

   function KeyNodeDatum(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node,"NodeIsDatum"));
   }

   function KeyNodeUnregisterStart(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "NodeUnregisterStart"));
   }

   function KeyNodeProofRequestsForAddress(address node) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(node, "StorageProofsForAddress"));
   }

   function KeyNodeProofRequestTime(address node, bytes32 dataHash) public pure returns(bytes32) {
           return keccak256(
            abi.encodePacked(dataHash, node , "StorageProofRequestTimestamp"));
   }

   function KeyNodeProofWorkStatus(address node, bytes32 dataHash) public pure returns(bytes32) {
            return keccak256(
            abi.encodePacked(dataHash, node , "StorageProofWorkStatus"));
   }

    function KeyNodeProofRequestCreator(address node, bytes32 dataHash) public pure returns(bytes32) {
            return keccak256(
            abi.encodePacked(dataHash, node , "StorageProofRequestCreator"));
   }

   function KeyNodeProofSnarksVerified(address node, bytes32 dataHash) public pure returns(bytes32) {
            return keccak256(
            abi.encodePacked(dataHash, node , "StorageProofSnarksVerified"));
   }

   function KeyNodeProofChunkRequested(address node, bytes32 dataHash) public pure returns(bytes32) {
            return keccak256(
            abi.encodePacked(dataHash, node , "StorageProofRequestChunk"));
   }



     
    


}