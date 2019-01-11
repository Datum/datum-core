const web3 = global.web3;
var Datum = require('datum-sdk');
const MarketplaceContract = artifacts.require('MarketplaceContract');
const VaultManager = artifacts.require('VaultManager');
const RegistryContract = artifacts.require('DatumRegistry');
var datum = new Datum();

contract('MarketplaceContract', function (accounts) {
    let martketplace;
    let registry;

    //create new smart contract instance before each test method
    before(async function () {
        martketplace = await MarketplaceContract.new();
        registry = await RegistryContract.new();


        await martketplace.setRegistry(registry.address);
    });

    /*

    it("deposit", async function () {
        let amount = 10;

        //add amount to marketplace
        let deposited = await martketplace.deposit({ from: accounts[0], value: web3.toWei(amount, 'ether')  });

        assert.equal(deposited.logs[0].event, "Deposit", "Expected Deposit event")
    });


    it("withdrawal", async function () {
        let amount = 10;

        //add amount to marketplace
        let deposited = await martketplace.deposit({ from: accounts[0], value: web3.toWei(amount, 'ether')  });
        let withdrawal = await martketplace.withdrawal(web3.toWei(amount, 'ether'), { from: accounts[0] });

        assert.equal(withdrawal.logs[0].event, "Withdrawal", "Expected Withdrawal event")
    });

    it("add auction", async function () {
        let duration = 100;
        let minBid = 1;
        let bidStep = 1;
        let instantBuyPrice = 1000;
        let id = "18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";

        let result = await martketplace.addAuction(id, duration, minBid, bidStep, instantBuyPrice, { from: accounts[0] });
        let auctionStruct = await martketplace.dataAuctions.call(result.logs[0].args.id);

       
        assert.equal(result.logs[0].event, "DataAuctionAdded", "Expected DataAuctionAdded event")
    });


    it("add bid to auction (invalid no balance on virtual wallet)", async function () {
        let duration = 100;
        let minBid = 10;
        let bidStep = 1;
        let instantBuyPrice = 1000;
        let id = "18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";

        let result = await martketplace.addAuction(id, duration, minBid, bidStep, instantBuyPrice, { from: accounts[0] });
        let auctionStruct = await martketplace.dataAuctions.call(result.logs[0].args.id);

        let auctionId = result.logs[0].args.id;
        let amount = 10;
        
        let addError;

        try {
            let bidResult = await martketplace.bid(auctionId, amount, { from: accounts[0] });
        } catch (error) {
            addError = error;
        }
      
        assert.notEqual(addError, undefined, 'Error must be thrown');
    });


    it("add bid to auction (valid balance exists)", async function () {
        let duration = 100;
        let minBid = 10;
        let bidStep = 1;
        let instantBuyPrice = 1000;
        let id = "18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";

        let amount = 10;

        //add amount to marketplace
        let deposited = await martketplace.deposit({ from: accounts[0], value: web3.toWei(amount, 'ether')  });

        //create auction
        let result = await martketplace.addAuction(id,duration, minBid, bidStep, instantBuyPrice, { from: accounts[0] });
        let auctionStruct = await martketplace.dataAuctions.call(result.logs[0].args.id);

        let auctionId = result.logs[0].args.id;

        let bidResult = await martketplace.bid(auctionId, web3.toWei(amount, 'ether'), { from: accounts[0] });

        assert.equal(bidResult.logs[0].event, "AuctionBid", "Expected AuctionBid event")

    });

    */

    describe('email blast tests', async function () {

        let signature;
        let signature2
        let fixed_msg_sha2;
        var keystoreDatum = {"encSeed":{"encStr":"DR888xPoa8Y93LtkfNIq8docDvGPzS6ZLiRqv/SZ8LpO9m7JnEWnffzvy30Z5rAOmtnwdCpLmmKtMV8pzfOFm8eRqCdrtv/qBcQ5+IsxhBfpXDQ9qwewvefd2nBHJENb945L12w6ABgya6DdeLpz1/V7NlQPCZ8tuyNh+zvLoPJqeepA269ZKg==","nonce":"i9CRPAKwit8zY6yzbZ3+ICKhXaOq1Ham"},"encHdRootPriv":{"encStr":"CkKxJAz4zv7saOgItKepTPy/DwoG/0VOAfZ6bY/Zkc35ZQF4Wh92lbVhHI/NCsIGaBSPweyl498g1dke6GFT9pzkZvDcvCMjT3r6r8KOEt/imc0a7Yf/ciYerDgnhIohx80owfLobC5AcJ4IiTkptoIOhidEu0141J2dyxAIOA==","nonce":"rc3jitqtM2n4nsWYbJ+8IT4UkiB7NfTw"},"addresses":["ddaeb0a57b3b275635a65b9c029d80dceb55645d"],"encPrivKeys":{"ddaeb0a57b3b275635a65b9c029d80dceb55645d":{"key":"9dl0SfvtagoiIaugQuTUjru83b0wjvmpWBxsnGfDBKb+mZ5V9NJgJ7Df8o+3Mn/w","nonce":"r8GpH60DBquCXNnQR0e1JP2waOSUup8h"}},"hdPathString":"m/44\'/60\'/0\'/0","salt":"MzXvzhJlfR/JUkMx1oXlFm3nXZND6w0X22gHwBv1Dx4=","hdIndex":1,"version":3};
        datum.initialize({ network: "http://127.0.0.1:9545",  identity: JSON.stringify(keystoreDatum)});
        datum.identity.storePassword("re!Ej`3u[V'd?z%P@L]r,H7h");

        let userAddress = "0x3dedb074f2f6bd824311e2b83564ceaea3d84876"; //has 0 balance in testrpc

        before(async function () {
            //creat email claim from account[0]
            let subject = userAddress;
            let key = "0x454d41494c000000000000000000000000000000000000000000000000000000"; // "EMAIL";
            let value = "0x666c6f7269616e40646174756d2e6f7267000000000000000000000000000000"; // "florian@datum.org";
            let keyModifier = "0x38EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6"; // key for level claim
            let fixed_msg_sha = web3.sha3(subject, key, value);
            signature = await datum.identity.signMsgHash(fixed_msg_sha);

            //set email claim for account 0
            let claim = await registry.setClaim(subject, key, value,  signature.v, "0x" + signature.r.toString("hex"), "0x" + signature.s.toString("hex"),{ from: accounts[0]});

            //set modifier claim with level 2
            let claim2 = await registry.setClaim(subject, keyModifier, "0x3300000000000000000000000000000000000000000000000000000000000000",  signature.v, "0x" + signature.r.toString("hex"), "0x" + signature.s.toString("hex"),{ from: accounts[0]});

            //create signature for email
            fixed_msg_sha2 = datum.web3Manager.sha3(subject);
            signature2 = await datum.identity.signMsgHash(fixed_msg_sha2);

        });

        it("add email blast (without modifier)", async function () {
            let depositAmount = 1000;
            let blast_id = "0x18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
            let baseReward = 5000000000000000000;
            let claimsNeeded = ["0x454d41494c000000000000000000000000000000000000000000000000000000"];
            let rewardModifier = '';
            let rewardAmounts = [];
    
            //create email blast and deposit 100 DAT
            let blast = await martketplace.addSigningProofRequest(blast_id, baseReward, claimsNeeded, rewardModifier, rewardAmounts, { from: accounts[0], value: web3.toWei(depositAmount, 'ether')});
            
            assert.equal(blast.logs[1].event, "SigningProofRequestCreated", "Expected SigningProofRequestCreated event")
            assert.equal(blast.logs[1].args.id.toLowerCase(), blast_id.toLowerCase(), "Expected blast id should be: " + blast_id );
            assert.equal(blast.logs[1].args.creator, accounts[0], "Expected creator should be: " + accounts[0]);
        });
    
    
        it("add email blast (with modifier)", async function () {
            let depositAmount = 1000; //deposit amount in DAT to payout the rewards
            let blast_id = "0x3132336162633132330000000000000000000000000000000000000000000000"; //id of the email blast, must be unique
            let baseReward = 5000000000000000000; //base rewards in DAT (wei)
            let claimsNeeded = ['0x454d41494c000000000000000000000000000000000000000000000000000000']; //array of claim keynames that need to exists  and signed by creator of request
            let rewardModifier = "0x38EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6"; //key name of rewardModifier claim / level claim
            let rewardAmounts = [0, 0, 5000000000000000000, 15000000000000000000, 45000000000000000000, 95000000000000000000]; //array of extraRewards per Level in Dat (wei)
    
            let blast = await martketplace.addSigningProofRequest(blast_id, baseReward, claimsNeeded, rewardModifier, rewardAmounts, { from: accounts[0], value: web3.toWei(depositAmount, 'ether')});
            
            assert.equal(blast.logs[1].event, "SigningProofRequestCreated", "Expected SigningProofRequestCreated event")
            assert.equal(blast.logs[1].args.id.toLowerCase(), blast_id.toLowerCase(), "Expected blast id should be: " + blast_id );
            assert.equal(blast.logs[1].args.creator, accounts[0], "Expected creator should be: " + accounts[0]);
        });

        it("check reward", async function () {
            let blast_id = "0x18EE24150DCB1D96752A4D6DD0F20DFD8BA8C38527E40AA8509B7ADECF78F9C6";
            let result = await martketplace.proofSigningRequest(blast_id, userAddress, signature2.v, "0x" + signature2.r.toString("hex"), "0x" + signature2.s.toString("hex"));
            let baseReward = 5000000000000000000;
            let balanceUser = await datum.web3Manager.getBalance(userAddress);

            assert.equal(balanceUser, baseReward, "Balance should be :" + baseReward);
            assert.equal(result.logs[0].event, "RewardReceived", "Expected RewardReceived event");
        });

        it("check reward with modifier", async function () {
            let blast_id = "0x3132336162633132330000000000000000000000000000000000000000000000";
            let result = await martketplace.proofSigningRequest(blast_id, userAddress, signature2.v, "0x" + signature2.r.toString("hex"), "0x" + signature2.s.toString("hex"));
            let baseReward = 5000000000000000000;
            let balanceUser = await datum.web3Manager.getBalance(userAddress);

            assert.equal(balanceUser, baseReward  , "Balance should be :" + baseReward);
            assert.equal(result.logs[0].event, "RewardReceived", "Expected RewardReceived event");
        });

        it("try double claim (should be rejected)", async function () {

            let addError;
            let blast_id = "0x3132336162633132330000000000000000000000000000000000000000000000";

            try {
                //contract throws error here
                await martketplace.proofSigningRequest(blast_id, userAddress, signature2.v, "0x" + signature2.r.toString("hex"), "0x" + signature2.s.toString("hex"));
            } catch (error) {
                addError = error;
            }

            assert.notEqual(addError, undefined, 'Error must be thrown');
        });

    });

    
    
    

 
});