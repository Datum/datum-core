const web3 = global.web3;
const MarketplaceContract = artifacts.require('MarketplaceContract');
const VaultManager = artifacts.require('VaultManager');

contract('MarketplaceContract', function (accounts) {
    let martketplace;


    //create new smart contract instance before each test method
    beforeEach(async function () {
        martketplace = await MarketplaceContract.new();
    });


    it("set vault manager from owner", async function () {
        //create new vault
        let newVault = await VaultManager.new();

        //set vault
        let result = await martketplace.setVaultManager(newVault.address, { from: accounts[0] });

        //read vault from contract
        let contractVault = await martketplace.vault.call();

        //check if new adddres correctly set
        assert.equal(contractVault, newVault.address, "Expected vault set to new vault")
    });


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
    

 
});