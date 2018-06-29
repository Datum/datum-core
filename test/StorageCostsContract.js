const web3 = global.web3;
const StorageCostsContract = artifacts.require('StorageCostsContract');

contract('StorageCostsContract', function (accounts) {
    let storageCosts;


     //create new smart contract instance before each test method
    beforeEach(async function () {
        storageCosts = await StorageCostsContract.new();
    });

    it("get storage costs for 1GB for 30 days which should be 5$ , around 222 DATCoins", async function () {

        //get storage costs in DATCoins for 1GB for 30 days without download costs
        let costsForOneDB = await storageCosts.getStorageCosts(1048576000,30);
       
        assert.equal(costsForOneDB.toNumber(), 222776688646291460000, "storage costs must be 222776688646291460000 ~5$");
    });

    it("get traffic costs for 1GB 1x time downloaded ~1$ , around 44 DATCoins", async function () {

        //get storage costs in DATCoins for 1GB for 30 days without download costs
        let costsForOneTransfer = await storageCosts.getTrafficCosts(1048576000,1);

     
       
        assert.equal(costsForOneTransfer.toNumber(), 44555337729048580000, "storage costs must be 44555337729048580000 ~1$");
    });

    it("get traffic costs for 10GB , around 440 DATCoins", async function () {

        //get storage costs in DATCoins for 1GB for 30 days without download costs
        let costsForOneTransfer = await storageCosts.getTrafficCostsGB(10);

     
       
        assert.equal(costsForOneTransfer.toNumber(), 445553377294590000000, "storage costs must be 445553377294590000000 ~10$");
    });
});