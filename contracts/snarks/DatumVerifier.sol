pragma solidity ^0.4.23;

import "./Verifier.sol";

//contract to verify proofs done by storage nodes, used internal in other contracts
contract DatumVerifier
{

    event VerificationStatus(bool success);

    //verify a zero knowledge proof done by a storage node, return true/false
	function Verify (
        uint256[] alpha, 
        uint256[2][2] beta, 
        uint256[2][2] gamma, 
        uint256[2][2] delta, 
        uint256[2][3] gammaABC,
        uint256[] proofA,
        uint256[2][2] proofB,
        uint256[] proofC,
        uint256[] input) public returns (bool bSuccess)
	{
		Verifier.VerifyingKey memory vk;

        vk.beta = Pairing.G2Point(beta[0], beta[1]);
        vk.gamma = Pairing.G2Point(gamma[0], gamma[1]);
        vk.delta = Pairing.G2Point(delta[0], delta[1]);
		vk.alpha = Pairing.G1Point(alpha[0], alpha[1]);
		
        vk.gammaABC = new Pairing.G1Point[](3);
		vk.gammaABC[0] = Pairing.G1Point(gammaABC[0][0],gammaABC[0][1]);
        vk.gammaABC[1] = Pairing.G1Point(gammaABC[1][0],gammaABC[1][1]);
        vk.gammaABC[2] = Pairing.G1Point(gammaABC[2][0],gammaABC[2][1]);

        Verifier.Proof memory proof;
    	proof.B = Pairing.G2Point(proofB[0], proofB[1]);
		proof.A = Pairing.G1Point(proofA[0], proofA[1]);
		proof.C = Pairing.G1Point(proofC[0], proofC[1]);
	
        bool bRet = Verifier.Verify(vk, proof, input);
       
        return bRet;
	}
}
