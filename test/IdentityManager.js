const web3 = global.web3;
const MetaIdentityManager = artifacts.require('MetaIdentityManager');
const Proxy = artifacts.require('Proxy')
const StorageNodeContract = artifacts.require('StorageNodeContract');
const VaultManager = artifacts.require('VaultManager');
const StorageCostsContract = artifacts.require('StorageCostsContract');
const lightwallet = require('eth-lightwallet')
const leftPad = require('left-pad')
const MetaTxRelay = artifacts.require('TxRelay')
const solsha3 = require('solidity-sha3').default

const userTimeLock = 50;
const adminTimeLock = 100;
const adminRate = 50;

var signing = lightwallet.signing


function enc(funName, types, params) {
    return lightwallet.txutils._encodeFunctionTxData(funName, types, params)
}

function pad(n) {
    assert.equal(typeof (n), 'string', "Passed in a non string")
    let data
    if (n.startsWith("0x")) {
        data = '0x' + leftPad(n.slice(2), '64', '0')
        assert.equal(data.length, 66, "packed incorrectly")
        return data;
    } else {
        data = '0x' + leftPad(n, '64', '0')
        assert.equal(data.length, 66, "packed incorrectly")
        return data;
    }
}



let seed = 'unhappy nerve cancel reject october fix vital pulse cash behind curious bicycle'

function sign(address, hash, password) {
    return new Promise((resolve, reject) => {
        lightwallet.keystore.createVault(
            {
                hdPathString: "m/44'/60'/0'/0",
                seedPhrase: seed,
                password: password
            },
            function (err, keystore) {
                if (err) {
                    reject('Error creating vault:' + err.message);
                }

                lw = keystore
                lw.keyFromPassword(password, async function (e, k) {
                    keyFromPw = k
                    lw.generateNewAddress(k, 10)
                    var sig = signing.signMsgHash(lw, keyFromPw, hash, address)
                    var retVal = {};
                    retVal.r = '0x' + sig.r.toString('hex')
                    retVal.s = '0x' + sig.s.toString('hex')
                    retVal.v = sig.v //Q: Why is this not converted to hex?
                    resolve(retVal);
                });
            }
        );
    });

}

contract('MetaIdentityManager ', function (accounts) {
    let identityManager;
    let deployedProxy;
    let testReg;

    let txRelay;
    let sampleUser;
    let sampleDeveleoper;
    let sampleThridParty;

    let recoveryKey;
    let nobody;

    before(async function () {
        sampleUser = accounts[0];
        sampleDeveleoper = accounts[1];
        sampleThridParty = accounts[2];
        recoveryKey = accounts[8];

        nobody = accounts[5]; // has no authority

        txRelay = await MetaTxRelay.new();

        identityManager = await MetaIdentityManager.new(userTimeLock, adminTimeLock, adminRate, txRelay.address)
    });

    it('Correctly creates Identity', async function () {
        let tx = await identityManager.createIdentity(sampleUser, recoveryKey, { from: nobody });
        let log = tx.logs[0];

        assert.equal(log.event, 'LogIdentityCreated', 'wrong event')
        assert.equal(log.args.owner, sampleUser, 'Owner key is set in event')
        assert.equal(log.args.recoveryKey, recoveryKey, 'Recovery key is set in event')
        assert.equal(log.args.creator, nobody, 'Creator is set in event')

        let proxyController = await Proxy.at(log.args.identity).owner.call()
        assert.equal(proxyController, identityManager.address, 'Proxy owner should be the identity manager')
    })

    it('User can deposit to his identity', async function () {
        let tx = await identityManager.createIdentity(sampleUser, recoveryKey, { from: nobody });
        let log = tx.logs[0];
        let proxy = await Proxy.at(log.args.identity);
        let proxyController = await proxy.owner.call()
        let isOwner = await identityManager.isOwner(log.args.identity, sampleUser);

        let balance = await web3.eth.getBalance(sampleUser);
        let result = await proxy.send(web3.toWei(0.5, "ether"));
        let balanceProxy = await web3.eth.getBalance(log.args.identity);
        let balanceAfter = await web3.eth.getBalance(sampleUser);

        assert.equal(balanceProxy, web3.toWei(0.5, "ether"), 'Proxy balance should be deposit value')
        assert.equal(proxyController, identityManager.address, 'Proxy owner should be the identity manager')
        assert.isTrue(isOwner, 'sampleUser should be owner of identity in IdentityManager');

    })

    
    describe('test with deposit done and ready to act', function () {

        let proxy;
        let storage;
        let vault;
        let registrator;
        let costs;


        let hash = "0x18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let hash2 = "0x28EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let hash3 = "0x38EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let root = "0x13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let secret = "0x5d521323580bc303b1dd9cf4f9dc3a90049a2a5aceb5e005233df99fac70d0edad1749cfee8744507992fa14ff682bc56a1955c3697f2b50ee409476cf6f75b8782bcc2fd2de3979d0f7e1285e990487599bf93686f165a5e47ec79e3089c821ac097e437caed37c43fa1a6625cab619a302da47ea50be6bba0124d3a893982f260fc8b0eb8d87ad8d88d25b76bc57f3e7";
        let secret2 = "0x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a2";
        let size = 10234;
        let keyname = "TEST";
        let keys = [];
        let category = "email";
        let replicationMode = 1;
        let privacy = 1;
        let duration = 100;
        let price = 100;


        before(async function () {
            sampleUser = accounts[0];
            sampleDeveleoper = accounts[1];
            sampleThridParty = accounts[2];
            relay = accounts[6]
            recoveryKey = accounts[8];
    
            nobody = accounts[5]; // has no authority
    
            identityManager = await MetaIdentityManager.new(userTimeLock, adminTimeLock, adminRate, relay)

            vault = await VaultManager.new();
            costs = await StorageCostsContract.new();
            storage = await StorageNodeContract.new(vault.address, costs.address);

            let tx = await identityManager.createIdentity(sampleUser, recoveryKey, { from: nobody });
            let log = tx.logs[0];
            proxy = await Proxy.at(log.args.identity);
            let result = await proxy.send(web3.toWei(0.5, "ether"));

            await vault.transferOperator(storage.address);

        });

        it('User can send send DAT over proxy', async function () {
            let balanceO = await web3.eth.getBalance(proxy.address);

            let balance = await web3.eth.getBalance(sampleUser);
            let result = await identityManager.forward(proxy.address, nobody, web3.toWei(0.5, "ether"), '', { from: sampleUser });
            let balanceAfter = await web3.eth.getBalance(sampleUser);

            balanceO = await web3.eth.getBalance(proxy.address);
            assert.isBelow(balanceAfter.toNumber(), balance.toNumber(),  'Proxy owner should be the identity manager')
        })

        
        it('deposit to storage', async function () {
            //types = ['address','bytes32','bytes32','bytes32','uint256','uint','uint','uint','bytes'];
            //params = [proxy.address, hash, root, web3.toHex(keyname), size, duration, replicationMode, privacy, secret];

            await proxy.send(web3.toWei(0.5, "ether"));

            types = ['address'];
            params = [proxy.address];

            data = enc('deposit', types, params);

            let result = await identityManager.forward(proxy.address, storage.address, web3.toWei(0.1, "ether") , data , { from: sampleUser  });

            let balance = await storage.getDepositBalance(proxy.address);

            assert.equal(balance, web3.toWei(0.1, "ether") ,  'Deposit balance should be in contract')
         })

         it('set strorage item', async function () {

            let balance = await web3.eth.getBalance(sampleUser);
            await proxy.send(web3.toWei(0.5, "ether"), { from: sampleUser  });
            balance = await web3.eth.getBalance(sampleUser);

            types = ['address','bytes32','bytes32','bytes32','uint256','uint256','uint256','uint256','bytes'];
            params = [proxy.address, hash, root, keyname, size, duration, replicationMode, privacy, secret];

            data = enc('setStorage', types, params);

            let result = await identityManager.forward(proxy.address, storage.address,  web3.toWei(0.1, "ether") , data , { from: sampleUser  });

            let item = await storage.getItemForId(hash);

            assert.isTrue(item[9], 'item should exist in contract');
           
         })
    });
    


    describe('developer pays for user', function () {

        let proxy;
        let proxyUser;
        let storage;
        let vault;
        let registrator;
        let costs;


        let hash = "0x18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let hash2 = "0x28EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let hash3 = "0x38EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
        let root = "0x13C78C707B010724CD9E1F596B58246A2C829384FC8A8A4B49AA38B3FDDFC1C2";
        let secret = "0x5d521323580bc303b1dd9cf4f9dc3a90049a2a5aceb5e005233df99fac70d0edad1749cfee8744507992fa14ff682bc56a1955c3697f2b50ee409476cf6f75b8782bcc2fd2de3979d0f7e1285e990487599bf93686f165a5e47ec79e3089c821ac097e437caed37c43fa1a6625cab619a302da47ea50be6bba0124d3a893982f260fc8b0eb8d87ad8d88d25b76bc57f3e7";
        let secret2 = "0x7fe5b21c5edb868e1494f30813864653041ec18e051b1670b0437beee0ca1d890d32e2dcd7498ae298557a66325ae8a6be0347189915075577bc3059adff2c25cffcecccd984f44a8567fa158215d6df86031b1d9c235fd5a34383ff26a63dc81ea32cb52087df04fef83e0ee3e85cc7ddce9adfe3695ea16b2ee52a6bec2c78aae8ff1615ff59192bf8b2de07658ef3a2";
        let size = 10234;
        let keyname = "TEST";
        let keys = [];
        let category = "email";
        let replicationMode = 1;
        let privacy = 1;
        let duration = 100;
        let price = 100;

        let freshUser;


        

        before(async function () {





            sampleUser = accounts[0];
            sampleDeveleoper = accounts[1];
            sampleThridParty = accounts[2];

            recoveryKey = accounts[8];

            nobody = accounts[5]; // has no authority

            identityManager = await MetaIdentityManager.new(userTimeLock, adminTimeLock, adminRate, txRelay.address)

            vault = await VaultManager.new();
            costs = await StorageCostsContract.new();
            storage = await StorageNodeContract.new(vault.address, costs.address);

            //developer creates identity for him
            let tx = await identityManager.createIdentity(sampleDeveleoper, recoveryKey, { from: sampleDeveleoper });
            let log = tx.logs[0];
            proxy = await Proxy.at(log.args.identity);

            //developer creates identity for user
            tx = await identityManager.createIdentity(sampleUser, recoveryKey, { from: sampleDeveleoper });
            log = tx.logs[0];
            proxyUser = await Proxy.at(log.args.identity);

            //fill the proxy with some DAT's
            let result = await proxy.send(web3.toWei(10, "ether"));

            await vault.transferOperator(storage.address);

            await txRelay.register({ from: sampleDeveleoper });


            return new Promise((resolve, reject) => {
                lightwallet.keystore.createVault(
                    {
                        hdPathString: "m/44'/60'/0'/0",
                        seedPhrase: seed,
                        password: "test"
                    },
                    function (err, keystore) {
                        if (err) {
                            reject('Error creating vault:' + err.message);
                        }
        
                        lw = keystore
                        lw.keyFromPassword("test", async function (e, k) {
                            lw.generateNewAddress(k, 10)
                            let acct = lw.getAddresses()
                            freshUser = acct[0];
                            resolve();
                        });
                    }
                );
            });


          

        });

        it('Developer can send DAT over his proxy proxy', async function () {
            let balance = await web3.eth.getBalance(proxy.address);
            let result = await identityManager.forward(proxy.address, nobody, web3.toWei(0.5, "ether"), '', { from: sampleDeveleoper });
            let balanceAfter = await web3.eth.getBalance(proxy.address);

            assert.isBelow(balanceAfter.toNumber(), balance.toNumber(), 'Proxy owner should be the identity manager')
        })

        it('Developer can make transaction for user', async function () {
            types = ['address', 'bytes32', 'bytes32', 'bytes32', 'uint256', 'uint256', 'uint256', 'uint256', 'bytes'];
            params = [freshUser, hash, root, keyname, size, duration, replicationMode, privacy, secret];
            data = enc('setStorage', types, params);

            let nonce = await txRelay.getNonce.call(freshUser)
            hashInput = '0x1900' + txRelay.address.slice(2) + sampleDeveleoper.slice(2) + pad(nonce.toString('16')).slice(2)
                + identityManager.address.slice(2) + data.slice(2)
            hash = solsha3(hashInput);

            //user signs transaction
            var ret = await sign(freshUser, hash, "test");

            let typesMeta = ['address', 'address', 'address', 'uint256', 'bytes']
            let paramsMeta = [freshUser, proxy.address, storage.address, web3.toWei(0.5, "ether"), data]
            let dataMeta = enc('forwardTo', typesMeta, paramsMeta);

            //developer execute transaction
            let result = await txRelay.relayMetaTx(ret.v,ret.r,ret.s,identityManager.address, dataMeta, sampleDeveleoper, { from: sampleDeveleoper });

            assert.equal(result, dataMeta, 'Proxy owner should be the identity manager')
        })

        it('Others can NOT send over metaTx with their identity', async function () {
            types = ['address', 'bytes32', 'bytes32', 'bytes32', 'uint256', 'uint256', 'uint256', 'uint256', 'bytes'];
            params = [proxy.address, hash, root, keyname, size, duration, replicationMode, privacy, secret];
            data = enc('setStorage', types, params);

            let typesMeta = ['address', 'address', 'address', 'uint256', 'bytes']
            let paramsMeta = [sampleDeveleoper, proxyUser.address, storage.address, web3.toWei(0.5, "ether"), data]
            let dataMeta = enc('forwardTo', typesMeta, paramsMeta);


            let errorThrown = false;


            try {
                let result = await txRelay.relayMetaTx(identityManager.address, dataMeta, sampleDeveleoper, { from: sampleUser });
            } catch (error) {
                errorThrown = true;
            }

            assert.isTrue(errorThrown, "Error should be thrown");
        })

        it('Others can NOT send over metaTx with developer identity', async function () {
            types = ['address', 'bytes32', 'bytes32', 'bytes32', 'uint256', 'uint256', 'uint256', 'uint256', 'bytes'];
            params = [proxy.address, hash, root, keyname, size, duration, replicationMode, privacy, secret];
            data = enc('setStorage', types, params);

            let typesMeta = ['address', 'address', 'address', 'uint256', 'bytes']
            let paramsMeta = [sampleDeveleoper, proxy.address, storage.address, web3.toWei(0.5, "ether"), data]
            let dataMeta = enc('forwardTo', typesMeta, paramsMeta);

            let errorThrown = false;

            try {
                let result = await txRelay.relayMetaTx(identityManager.address, dataMeta, sampleDeveleoper, { from: sampleUser });
            } catch (error) {
                errorThrown = true;
            }

            assert.isTrue(errorThrown, "Error should be thrown");
        })

        it('Developer can add others to use his metaTxService', async function () {

            var toAdd = [];
            toAdd.push(sampleUser);
            await txRelay.addToWhitelist(toAdd, { from: sampleDeveleoper });

            let isAllowed = await txRelay.isInWhitelist(sampleDeveleoper, { from: sampleUser });
            assert.isTrue(isAllowed, "user should be in allowance list");
        })
    });
});