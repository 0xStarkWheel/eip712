import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";

import { destruct_uint, felthex, feltstr, addr, feltnum, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext } from "../scripts/util";
const ethUtil = require('ethereumjs-util');
import { reconfig, encodeType, typeHash, encodeData, typedData, structHash, signHash, } from "../scripts/signature"
import { uint256 } from "starknet";
// using ethereumjs-abi 0.6.9
const abi = require('ethereumjs-abi');

// analyse event and do callBack
describe("Signature", function () {

    this.timeout(TIMEOUT);

    const privateKey = ethUtil.keccakFromString('cow', 256);
    const address = ethUtil.privateToAddress(privateKey);
    const sig = ethUtil.ecsign(signHash(), privateKey);

    let ctx: any = getInitialContext();


    it("Should signature.ts work", async () => {
        expect(encodeType('Vote')).to.equal('Vote(address from,uint256 proposal,uint256 choice)');
        expect(ethUtil.bufferToHex(typeHash('Vote'))).to.equal(
            '0xf1e6f447934110cc3624c4393bf6960736336e8f86e0717a73a4500320f064d0',
        );
        expect(ethUtil.bufferToHex(encodeData(typedData.primaryType, typedData.message))).to.equal(
            '0xf1e6f447934110cc3624c4393bf6960736336e8f86e0717a73a4500320f064d0000000000000000000000000cd2a3d9f938e13cd947ec05abc7fe734df8dd826000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000000000003',
        );
        expect(ethUtil.bufferToHex(structHash(typedData.primaryType, typedData.message))).to.equal(
            '0xa265a9749d0a362376d680c2d8f717f79accb958c78f33e599c1b587218f7824',
        );
        expect(ethUtil.bufferToHex(structHash('EIP712Domain', typedData.domain))).to.equal(
            '0xcc9fd420edcfef4ea1e26017afcd69c4334094b20d333cffb3597fdf5d63eeae',
        );
        expect(ethUtil.bufferToHex(signHash())).to.equal('0xbfa69bf56fc2dc335488861092d8125104c1f1a0ae63e89a85a8ef0ec5256a91');
        expect(ethUtil.bufferToHex(address)).to.equal('0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826');
        expect(sig.v).to.equal(27);
        expect(ethUtil.bufferToHex(sig.r)).to.equal('0x540e3e3e6ddc34b1a23fb1b2d9f334e5f44df9d9d2e6df71dfd97dd92a50ede4');
        expect(ethUtil.bufferToHex(sig.s)).to.equal('0x1647075b97d5ec7480e9bfbebb0325457d358047f3dbb3c72f1b1bb08b9987b7');
        // console.log("signature", destruct_uint(sig.r))

        await ctx.deployEthContracts([{ name: "vote", src: "Vote" }])
        try {
            await ctx.eth.vote.test()
        } catch (error) {
            console.log(error)
        }
    })

    it("Should Vote.cairo work", async () => {
        await ctx.deployContracts([
            { name: "vote", src: "Vote", params: { _vote_typehash: destruct_uint(typeHash('Vote')), } },
        ])

        // reconfig(ctx.vote.address)
        // console.log(ctx.vote.address)
        await ctx.vote.invoke("set_hashes", { _prefix: feltnum(Buffer.from('1901', 'hex')), _domain_separator: destruct_uint(structHash('EIP712Domain', typedData.domain)) })

        let { proposal, choice, from } = typedData.message;
        await ctx.vote.call("hash_vote", {
            proposal: { high: 0, low: feltnum(proposal) },
            choice: { high: 0, low: feltnum(choice) },
            voter: from,
        })

        const { res: res } = await ctx.vote.call("verify_vote", {
            proposal: { high: 0, low: feltnum(proposal) },
            choice: { high: 0, low: feltnum(choice) },
            voter: from,
            r: destruct_uint(sig.r),
            s: destruct_uint(sig.s),
            v: feltnum(sig.v),
        })
        console.log("res", res)
        console.log("vote_typehash", destruct_uint(signHash()))

    })

});