pragma solidity ^0.8.13;
import "hardhat/console.sol";

contract Vote {
    
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        uint256 verifyingContract;
    }

    struct Vote {
        uint256 proposal;
        uint256 choice ;
        address from ;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,uint256 verifyingContract)"
    );

    bytes32 constant VOTE_TYPEHASH = keccak256(
        "Vote(address from,uint256 proposal,uint256 choice)"
    );

    bytes32 DOMAIN_SEPARATOR;

    constructor (/*uint256 contract_address*/) public {
        address contract_address = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
        DOMAIN_SEPARATOR = hash(EIP712Domain({  
            name: "AuthenticateContract",
            version: '1',   
            chainId: 1,
            // verifyingContract: this
            verifyingContract: uint256(uint160(contract_address))
        }));
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(Vote memory vote) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            VOTE_TYPEHASH,
            vote.from,
            vote.proposal,
            vote.choice
        ));
    }

    function verify(Vote memory vote, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(vote)
        ));
        return ecrecover(digest, v, r, s) == vote.from;
    }
    
    function test() public view returns (bool) {
        // Example signed message
        Vote memory vote = Vote({
            from: 0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826,
            choice: 3,
            proposal: 13
        });
        uint8 v = 27;
        bytes32 r = 0x540e3e3e6ddc34b1a23fb1b2d9f334e5f44df9d9d2e6df71dfd97dd92a50ede4;
        bytes32 s = 0x1647075b97d5ec7480e9bfbebb0325457d358047f3dbb3c72f1b1bb08b9987b7;

        assert(DOMAIN_SEPARATOR == 0xcc9fd420edcfef4ea1e26017afcd69c4334094b20d333cffb3597fdf5d63eeae);
        assert(hash(vote) == 0xa265a9749d0a362376d680c2d8f717f79accb958c78f33e599c1b587218f7824);
        assert(verify(vote, v, r, s));
        return true;
    }
}