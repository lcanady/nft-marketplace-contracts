# NFT Marketplace Solidity Contracts

This repo contains the smart contracts component of the NFT Marketplace. This repo was created as part of the NetVRk skills challenge. Thanks for the opportunity guys, I had a great time. :)

## DEV

```shell
git clone  https://github.com/lcanady/nft-marketplace.git
cd nft-marketplace
'yarn' or 'npm install'
'yarn test' or 'npm run test'

```

## Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
