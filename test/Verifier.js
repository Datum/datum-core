const web3 = global.web3;
const TestVerifier = artifacts.require('DatumVerifier');

contract('DatumVerifier', function (accounts) {
    let verifier;

    //test params
    let alpha = ["0x1f9a98398a35ed657c5bce6fa942ab63321d056b70379396ef1225e3d57585f1", "0xb852339f2de42c72bcab645a63498defcf23971c09674347c849d840a3280ed"];
    let beta = [["0x2ab21c0492ce748623548c3f2ba7c865b9a49be3664eae4308c7c946815204f6", "0x1345a8163d9dcf13e059cc714b78303d454db3426ce79fac20f5ddfb9acd39f3"],
    ["0x1b125e44f70519c9e7419d2ecb05901e2ae8aff8ffb51e487dc54b68833c4b19", "0x1c7c54c672b744ef4ccd23122a14cbb00097c8b711b221c31c5a590da6a9ad79"]];
    let gamma = [["0x2a63f2a028b3a4792010555686ab4f7d5d7f20ce1aca4f9b76513f988a3d47ff", "0x23a42cb41e1441ab5abeec3700a17b910bd94129e3e163a451f399a4efe19f9"],
    ["0x157e6f98a09b2f8c34ddf55f8d1f2f34796dc142bb119db2ed15639d5ad9d83a", "0x2b530baa246040971f31da61f6a2812ab755e703c9d5b4260108b913642bf7d3"]];
    let delta = [["0x1c57d9de57dee26a9680985294fb473a8dd1c779ea9ce19de673404a1522548a", "0x112eb1ccf9753d7470b94591f11aefbf7bb501d627fa548d35d2eb6a486a3652"],
    ["0xef0480f38225759d62b92987ac332a3b6f579f8036035569c283b8a8ab7b7d1", "0x1adea203983f46352aa3c2061575c70a6e67099fd93c21654762954318f4dd3c"]];
    let gammaABC = [["0xcff059aa3c0a286b2ff9f876e94ff0f491358dc9cbf94065c2a2c2f0b0b4736", "0x1ab1c5f26165245e52091c8a09935c0fdcec1ac6f959a05c4e34f64d3197dff8"],["0x1ea0340e50215c707cb35c8c4c9840b6f9c9f893ae69c4304f4301d9a685a4e8", "0x17e7e0dc628a6349fe87a03ac3579ea5fcb65b2613c7ccec3db3b24cf2fa1e34"],["0x6dce4156fca6ae61e5cff8fa47a00cee1fb11e5db1abb411266e82dec5c13aa", "0x2abf86a316eaacb84a1c3e8923e9870cef081573b77cc219da8ec8ceb10977c1"]];
    
    
    let proofA = ["0x13f046375ad61512f44ebbc20530aaf0579c6cd37fc7267141a7187b0fe0c0a8", "0x19b5419e9ec811f581e44548675afdb985d06fc5731b3d36586271e14480e25b"];
    let proofB = [["0x2d950f8026906215cc11d500ea5591746d02068108bbdf28f8874a96fd800411", "0x207319673c93593c728683c25c46bd81b178666bd462bc88c2d6422cba58b64b"],
    ["0x782d3964614ded7c89935dadfae097e2de4817bdb55d0f31f601703df205cac", "0x1ecad502736505f835908450159363bd0829ad60dc82536d2fe040b305f315cb"]];
    let proofC = ["0x302ae7e204f0fbe42b8370019ad1fadb527ef45e5d04ca5455a9ee9253698730", "0x72538b224d4598857a3e3299e9e9c909b9c24eb76d025d30d636a707724c60e"];
    let inputs = ["0x5b22c7b3f815688987dbaf6eb0676147d5712bbd17bc2dfe9e60736ae1b5a74", "0x1"];

    let inputsWrong = ["0x6b22c7b3f815688987dbaf6eb0676147d5712bbd17bc2dfe9e60736ae1b5a74", "0x1"];
   
    //create new smart contract instance before each test method
    beforeEach(async function () {
        verfifier = await TestVerifier.new();
    });

    it("test verfifier with valid proof", async function () {
        let result = await verfifier.Verify(alpha, beta, gamma, delta, gammaABC, proofA, proofB, proofC, inputs, { from: accounts[0] });
        assert.isTrue(result.logs[0].args.success,  "Verification should be true");
    });

    it("test verfifier with invalid proof", async function () {
        let result = await verfifier.Verify(alpha, beta, gamma, delta, gammaABC, proofA, proofB, proofC, inputsWrong, { from: accounts[0] });
        assert.isFalse(result.logs[0].args.success,  "Verification should be false");
    });
});