import hardhat from "hardhat";
const folder = 'contracts/'
const fs = require("fs")

async function main() {
    const contract_names: string[] = fs.readdirSync(folder)
    const contracts = contract_names.filter(_name => _name.endsWith(".cairo"))

    const paths = contracts.map(name => `contracts/${name}`)
    await hardhat.run("starknet-compile", {
        paths: paths
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
