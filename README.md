### Datum Smart Contracts

## Commands

truffle compile

truffle test

truffle deploy

## Deploy

truffle migrate --reset 


# VaultManager
Holds the virtual balance for a user in Datum Blockchain for Storage or Marketplace

# ForeverStorage
Shared contract to store data and sharing between other contracts. Includes different mappings types as key/value store. Main storage

# StorageContract
Handles all storage related parts, like creating storage space, access rules on storage items, etc

# StorageData
Data logic contract for storage contract

# Marketplace
Handles all the marketplace functions like adding data request, creating auctions, etc

# NodeRegistrator
Handles the storage nodes registration and payment

# NodeRegistratorData
Data logic contract for node registrator

# DatumRegistry
Handles the Datum Identity, creating user, add claims to user, etc

# RatingContract
Holds the rating for a Datum user based on public address and related to a data item

# DatumVerifier
Contract to verify zero-knowledge proofs done by storage nodes, used internal in other contracts





