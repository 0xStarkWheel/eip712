import fs from "fs"
import hardhat from "hardhat";
import { StarknetContract, Account } from "hardhat/types";
import { number } from "starknet"
import { ethers } from 'hardhat';
import { BigNumber, Contract, ContractFactory } from 'ethers';
import { expect } from "chai";
import { BN } from "ethereumjs-util";
const ethUtil = require('ethereumjs-util');

let contract;
const starknet = hardhat.starknet;
interface IAccount extends Account {
    address: string
}

interface IContractInfo {
    name: string;
    src: string;
    params: Object;

}

export async function deployAccounts(ctx: any, names: string[]) {
    const promiseContainer = names.map(name => starknet.deployAccount("OpenZeppelin"))
    const accounts: IAccount[] = (await Promise.all(promiseContainer)).map((account: any) => { account.address = account.starknetContract.address; return account })
    for (let i in accounts) {
        ctx[names[i]] = accounts[i]
    }
}

export function getInitialContext() {
    let ctx: any = {}
    ctx.eth = {}
    ctx.deployContracts = async (contractInfos: IContractInfo[]) => {

        await deployContracts(ctx, contractInfos)
    }

    ctx.deployEthContracts = async (contractInfos: IContractInfo[]) => {

        await deployEthContracts(ctx, contractInfos)
    }

    ctx.execute = async (_caller: string, _contract: string, selector: string, params: any) => {
        let account: IAccount = ctx[_caller]
        let contract: StarknetContract = ctx[_contract]

        let res = await account.invoke(contract, selector, params)
        return res
    }

    ctx.call = async (_caller: string, _contract: string, selector: string, params: any) => {
        let account: IAccount = ctx[_caller]
        let contract: StarknetContract = ctx[_contract]

        let res = await account.call(contract, selector, params)
        return res
    }

    ctx.deployAccounts = async (names: string[]) => {
        await deployAccounts(ctx, names)
    }
    return ctx
}


export async function deployContracts(ctx: any, contractInfos: IContractInfo[]) {
    let promiseContainer: Promise<StarknetContract>[] = []
    for (let i in contractInfos) {
        const { name, src, params } = contractInfos[i]
        const contractPromise: Promise<StarknetContract> = new Promise(async (resolve, reject) => {
            try {
                console.log(`contracts/${src}.cairo`)
                // await hardhat.run("starknet-compile", {
                //     paths: `contracts/${src}.cairo`
                // });
                const contractFactory = await starknet.getContractFactory(src)
                const contract = await contractFactory.deploy(params)
                resolve(contract)
            }
            catch (err) {
                reject(err)
            }
        })
        promiseContainer.push(contractPromise)
    }
    const result = await Promise.all(promiseContainer)

    for (let i in result) {
        const { name, src, params } = contractInfos[i]
        const contract = result[i]
        ctx[name] = contract
    }
}



export async function deployEthContracts(ctx: any, contractInfos: IContractInfo[]) {
    let promiseContainer: Promise<Contract>[] = []
    for (let i in contractInfos) {
        const { name, src, params } = contractInfos[i]
        const contractPromise: Promise<Contract> = new Promise(async (resolve, reject) => {
            try {
                console.log(`contracts/${src}.sol`)
                // await hardhat.run("starknet-compile", {
                //     paths: `contracts/${src}.cairo`
                // });
                const contractFactory = await ethers.getContractFactory(src);

                let p: any = params
                if (p == undefined) p = []
                const contract = await contractFactory.deploy(...p)
                resolve(contract)
            }
            catch (err) {
                reject(err)
            }
        })
        promiseContainer.push(contractPromise)
    }
    const result = await Promise.all(promiseContainer)

    for (let i in result) {
        const { name, src, params } = contractInfos[i]
        const contract = result[i]
        ctx.eth[name] = contract
    }
}

// name : felt,
// symbol : felt,
// decimals : felt,
// initial_supply : Uint256,
// recipient : felt,
// owner : felt,

export async function deployContext() {
    let ctx: any = {}
    await deployAccounts(ctx, ["alice", "bob", "carol", "dave", "amber", "kim", "shane"])
    console.log("alice", ctx.alice.starknetContract._address)
    return
    await deployContracts(ctx, [
        // deploy tokens
        { name: "usdt", src: "ERC20", params: { name: felt("usdt"), symbol: felt("usdt"), decimals: 2, initial_supply: { low: 100000, high: 0 }, recipient: felt(ctx.alice.address), owner: felt(ctx.alice.address) } },
        { name: "dai", src: "ERC20", params: { name: felt("dai"), symbol: felt("dai"), decimals: 2, initial_supply: { low: 100000, high: 0 }, recipient: felt(ctx.alice.address), owner: felt(ctx.alice.address) } },
        { name: "weth", src: "ERC20", params: { name: felt("weth"), symbol: felt("weth"), decimals: 2, initial_supply: { low: 100000, high: 0 }, recipient: felt(ctx.alice.address), owner: felt(ctx.alice.address) } },
        // deploy extensions
        { name: "feeManager", src: "FeeManager", params: {} },
        { name: "policyManager", src: "FeeManager", params: {} },
    ])


    return ctx
}


export function felt(str: string) {
    return starknet.shortStringToBigInt(str)
}
export function addr(str: string) {
    return number.toBN(str)
}
export function destruct_uint(a: any) {

    let v: bigint = BigInt(ethUtil.bufferToHex(a)) + 0n
    const low = v % (2n ** 128n)
    const high = v >> 128n
    return { low, high }
}
export function feltstr(str: string) {
    return number.toBN(str).toString()
}

export function felthex(str: string) {
    return number.toBN(str).toString("hex")
}
export function feltnum(str: any) {
    return number.toBN(str).toNumber()
}

export function fromfelt(_felt: any) {
    return starknet.bigIntToShortString(_felt)
}
// analyse event and do callBack
export function expect_eth(a: any, b: BigNumber) {
    expect(uint256_to_bn(a)).to.be.equal(b.toBigInt())
}
export function uint256_to_bn(a: any) {
    //@ts-ignore

    return a.high * (2n ** 128n) + a.low
}

export const timer = (ms: any) => new Promise(res => setTimeout(res, ms))

