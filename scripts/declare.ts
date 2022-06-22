import hardhat from "hardhat";
const folder = 'contracts/'
const fs = require("fs")
const { exec } = require("child_process");

async function main() {
    const contract_names: string[] = fs.readdirSync(folder)
    const contracts = ["MockOwnableContract"]

    const { stdout, stderr } = await exec('ls')
    // await exec(`starknet declare --contract starknet-artifacts/contracts/${contracts[0]}.cairo/${contracts[0]}.json`)
    console.log("stdout", stdout)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
