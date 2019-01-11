pragma solidity ^0.4.24;

import './ForeverStorage.sol';
import "./shared/Administratable.sol";
import "./StorageKeys.sol";

contract StorageData is Administratable {
    ForeverStorage public foreverStorage; //storage contract
    StorageKeys private storageKeys;

    constructor(address _forever, address _storageKeys) public {
        //by default a new vault manager is created, can be overwritten with setVaultManager
        foreverStorage = ForeverStorage(_forever);
        storageKeys = StorageKeys(_storageKeys);
    }

    //allow to change contract for migration 
    function setStorageContract(address _foreverStorage) onlyAdmins public
    {
        foreverStorage = ForeverStorage(_foreverStorage);
    }


    function set(bytes32 dataHash, address sender, address owner, bytes32 merkleRoot, uint256 size, string key,uint replicationMode, address[] trusted) public onlyAdmins {
        foreverStorage.setAddressByBytes32(storageKeys.KeyItemCreator(dataHash), sender);
        foreverStorage.setAddressByBytes32(storageKeys.KeyItemOwner(dataHash), owner);
        foreverStorage.setBytes32ByBytes32(storageKeys.KeyItemMerkle(dataHash), merkleRoot);
        foreverStorage.setUintByBytes32(storageKeys.KeyItemSize(dataHash), size);
        foreverStorage.setUintByBytes32(storageKeys.KeyItemCreated(dataHash), now);
        foreverStorage.setBytes32ByBytes32(storageKeys.KeyItemKey(dataHash), keccak256(abi.encodePacked(key)));
        foreverStorage.setUintByBytes32(storageKeys.KeyItemReplication(dataHash), replicationMode);

        uint storageItemCount = foreverStorage.getUintByBytes32(storageKeys.KeyItemCount());
        foreverStorage.setUintByBytes32(storageKeys.KeyItemCount(), storageItemCount.add(1));
                

        //set trusted addresses
        foreverStorage.setAddressArrayByBytes32(storageKeys.KeyItemTrusted(dataHash), owner);
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemForAddress(owner), dataHash);
        
        for(uint i =0; i < trusted.length;i++) {
            //if trusted address is same than owner, skip it to prevent double add
            if(trusted[i] != owner) {
                foreverStorage.setAddressArrayByBytes32(storageKeys.KeyItemTrusted(dataHash), trusted[i]);
                foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemForAddress(trusted[i]), dataHash);
            }
        }

        //set mappings and key mappings
        if(bytes(key).length != 0) {
            foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemForKey(owner, keccak256(abi.encodePacked(key))), dataHash);

            //add keys for trusted
            for(uint iKey =0; iKey < trusted.length;iKey++) {
                //if trusted address is same than owner, skip it to prevent double add
                if(trusted[iKey] != owner) {
                    foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemForKey(trusted[iKey], keccak256(abi.encodePacked(key))), dataHash);
                }
            }
        }
    }

    function setNode(address[] a, bytes32 dataHash, uint size) public onlyAdmins{
         //set as target nodes and inverse mappings
        foreverStorage.setAddressArrayByBytes32(storageKeys.KeyNodesForItem(dataHash), a[0]);
        foreverStorage.setAddressArrayByBytes32(storageKeys.KeyNodesForItem(dataHash), a[1]);
        foreverStorage.setAddressArrayByBytes32(storageKeys.KeyNodesForItem(dataHash), a[2]);
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemsForNode(a[0]), dataHash);
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemsForNode(a[1]), dataHash);
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemsForNode(a[2]), dataHash);

        uint lastSize0 = foreverStorage.getUintByBytes32(storageKeys.KeySizeForNode(a[0]));
        foreverStorage.setUintByBytes32(storageKeys.KeySizeForNode(a[0]), lastSize0.add(size));

        uint lastSize1 = foreverStorage.getUintByBytes32(storageKeys.KeySizeForNode(a[1]));
        foreverStorage.setUintByBytes32(storageKeys.KeySizeForNode(a[1]), lastSize1.add(size));

        uint lastSize2 = foreverStorage.getUintByBytes32(storageKeys.KeySizeForNode(a[2]));
        foreverStorage.setUintByBytes32(storageKeys.KeySizeForNode(a[2]), lastSize2.add(size));
    }


    function remove(address owner, bytes32 dataHash) onlyAdmins public returns(bool) {
        bytes32 key = foreverStorage.getBytes32ByBytes32(storageKeys.KeyItemKey(dataHash));
        uint size = foreverStorage.getUintByBytes32(storageKeys.KeyItemSize(dataHash));
        
        //remove storages
        foreverStorage.deleteAddressByBytes32(storageKeys.KeyItemCreator(dataHash));
        foreverStorage.deleteAddressByBytes32(storageKeys.KeyItemOwner(dataHash));
        foreverStorage.deleteBytes32ByBytes32(storageKeys.KeyItemMerkle(dataHash));
        foreverStorage.deleteUintByBytes32(storageKeys.KeyItemSize(dataHash));
        foreverStorage.deleteUintByBytes32(storageKeys.KeyItemCreated(dataHash));
        foreverStorage.deleteBytes32ByBytes32(storageKeys.KeyItemKey(dataHash));
        foreverStorage.deleteUintByBytes32(storageKeys.KeyItemReplication(dataHash));

        //update count
        uint storageItemCount = foreverStorage.getUintByBytes32(storageKeys.KeyItemCount());
        foreverStorage.setUintByBytes32(storageKeys.KeyItemCount(), storageItemCount.sub(1));

        //remove array storages
        address[] memory trusted = foreverStorage.getAddressesByBytes32(storageKeys.KeyItemTrusted(dataHash));
        for(uint i = 0;i < trusted.length;i++) {
            if(trusted[i] != owner) {
                foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyItemForAddress(trusted[i]), dataHash);
                foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyItemForKey(trusted[i], key),dataHash);
            }
        }
        

        
        foreverStorage.deleteAllAddressesFromArrayByBytes32(storageKeys.KeyItemTrusted(dataHash));
        foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyItemForAddress(owner),dataHash);
        foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyItemForKey(owner, key),dataHash);

        //removenodes
        address[] memory nodes = foreverStorage.getAddressesByBytes32(storageKeys.KeyNodesForItem(dataHash));
        for(uint n = 0;n < nodes.length;n++) {
            uint lastSize = foreverStorage.getUintByBytes32(storageKeys.KeySizeForNode(nodes[n]));
            if(lastSize > 0 && lastSize > size) {
                uint newSize = lastSize - size;
                foreverStorage.setUintByBytes32(storageKeys.KeySizeForNode(nodes[n]), newSize );
            }
        }
        foreverStorage.deleteAllAddressesFromArrayByBytes32(storageKeys.KeyNodesForItem(dataHash));
        
        

        //add to deleted mapping
        foreverStorage.setBoolByBytes32(storageKeys.KeyItemDeleted(dataHash), true);

        return true;
    }



    function addAccess(bytes32 dataHash, address wallet) onlyAdmins public returns(bool) {
         //set new address as trusted
        foreverStorage.setAddressArrayByBytes32(storageKeys.KeyItemTrusted(dataHash), wallet);
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemForAddress(wallet), dataHash);

        //check if item has key
        bytes32 key = foreverStorage.getBytes32ByBytes32(storageKeys.KeyItemKey(dataHash));
        foreverStorage.setBytes32ArrayByBytes32(storageKeys.KeyItemForKey(wallet, key),dataHash);

        return true;
    }
    
    function removeAccess(bytes32 dataHash, address wallet) onlyAdmins public returns(bool) {
        foreverStorage.deleteAddressFromArrayByBytes32(storageKeys.KeyItemTrusted(dataHash), wallet);
        foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyItemForAddress(wallet), dataHash);

        bytes32 key = foreverStorage.getBytes32ByBytes32(storageKeys.KeyItemKey(dataHash));
        foreverStorage.deleteBytes32FromArrayByBytes32(storageKeys.KeyItemForKey(wallet, key),dataHash);

        return true;
    }


}