# CUBE3 Gas Benchmarks

This repository demonstrates the gas usage of a simple ERC20 integration that utilizes the inherited `Cube3Integration` contract to interact with the CUBE3 protocol.

## Disclaimer

The contracts in this repo are for demonstration purposes only and are not fit for use in production. They were designed with the sole purpose of demonstrating the gas usage of a simple integration with the CUBE3 protocol.

## CUBE3 Protocol Contracts

Transactions were executed on the Goerli testnet using the following CUBE3 protocol contracts:

| Contract                    | Address                                    |
| --------------------------- | ------------------------------------------ |
| Cube3RouterProxy            | 0x5ec02641b145a7fde91261b983fd1743cb37b914 |
| Cube3RouterImplementation   | 0x03c299065f273bc583f6c2cd70a416583cb26b1a |
| Cube3RegistryProxy          | 0x8055e4f87cd04fda6e102971b45f20da77d3f9d2 |
| Cube3RegistryImplementation | 0x05c482a50cc5ffbe4465fdb057b3bd956840f08a |
| Cube3GateKeeper             | 0x5946959a7247f96ec4657ca0272c558f0ac11cc3 |
| Cube3SignatureModule        | 0x937f1c633e16dcddf995bd3c83fff7655a4686cb |

## Demo Contracts

The demonstration contracts are deployed on Goerli testnet at the following addresses:

| Contract                   | Address                                    |
| -------------------------- | ------------------------------------------ |
| GasBenchmarkToken          | 0x3261E5bd9E48d526d2fdCcbDeDa41117BA3aB0BB |
| GasBenchmarkTokenProtected | 0xc7133B4bE6ff42BF0e8982899699B9265EEae80d |

The source code for the two contracts deployed can be found at:

- src/ERC20Tokens.sol:GasBenchmarkToken (GBT)
- src/ERC20Tokens.sol:GasBenchmarkTokenProtected (GBTP)

The token contracts are functionally identical. However, the `GasBenchmarkTokenProtected` contract inherits the `Cube3Integration` contract and adds the `cube3Protected` modifier to the following functions:

- `whitelistClaimTokens`
- `disperseTokens`
- `transfer`

A full stack trace for each transaction is available in the `transaction_logs.txt` file.

## Gas Usage

The tables presented below describe the parameters of each function execution. `Function Protection Enabled` describes the `bool` value in the `_functionAuthorizationStatus` mapping of the `Cube3Integration` contract.

`Track Nonce` describes the boolean value included in the `cube3Payload` that dictates whether the nonce should be evaluated and incremented. A value of `true` indicates that the nonce will be incremented and stored and thus will add approximately `5,000` gas for the `SSTORE` to the storage slot with a non-zero value.

As demonstrated in the `transfer` table below, the `GBTP` token that includes the `Cube3Integration` contract, with the function protection status disabled, adds approximately `5,000` gas to the call due to the `SLOAD` of the `bool` value in the mapping. With function protection disabled, the payload is not routed through the payload and the additional gas is not required.

As a general rule of thumb, a function protected with the `cube3Protected` modifier will add approximately `50,000` gas to the call if the function protection is enabled and nonce tracking is disabled, and approximately `55,000` gas if the function protection is enabled and nonce tracking is also enabled. This value will increase slightly as the size of the `calldata` increases, as demonstrated by the `disperseTokens` function calls.

### transfer

- `function transfer(address to, uint256 amount)` (GBT)
- `function transfer(address to, uint256 amount, bytes calldata cube3Payload)` (GBTP)

The standard ERC20 `transfer` function transfers tokens from the sender to a recipient.

| Token | Function | Function Protection Enabled | Track Nonce | Etherscan                                                                                                      | Gas Used |
| ----- | -------- | --------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------- | -------- |
| GBT   | transfer | N/A                         | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0xfb9bbffdabba7952ab0d63facc75200196b781c080fb324abe09dd8760a88bcd) | 51,460   |
| GBTP  | transfer | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0x0a6068d120138393b55c6840ae79d688bb6ca01858e9ff6e1ccc09b7a46fc3dc) | 56,943   |
| GBTP  | transfer | TRUE                        | FALSE       | [Etherscan](https://goerli.etherscan.io/tx/0x21f3a3f180b7495c5776d7ec5c6bcdf9cda0a5e103a62ce64135756f8d5736cb) | 109,724  |
| GBTP  | transfer | TRUE                        | TRUE        | [Etherscan](https://goerli.etherscan.io/tx/0x6f13c0f646c3f2d269d2a709b3c5ffb1ef5d5d59897988d79a4bb1c062c46c45) | 114,967  |

### whitelistClaimTokens

- `function whitelistClaimTokens(uint256 amount)` (GBT)
- `function whitelistClaimTokens(uint256 amount, bytes calldata cube3Payload)` (GBTP)

The `whitelistClaimTokens` is an example of a function that allows a user to claim tokens whitelisted for them. It updates the balance in the `whitelist` mapping and performs a standard transfer.

| Token | Function             | Function Protection Enabled | Track Nonce | Etherscan                                                                                                      | Gas Used |
| ----- | -------------------- | --------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------- | -------- |
| GBT   | whitelistClaimTokens | N/A                         | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0x07cdcd9423d4c83d168d404d27b876974888ba4c45aa2479454862616c2c14da) | 51,487   |
| GBTP  | whitelistClaimTokens | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0xf260636d3cd6e73d602df6a8eaf3d96d88d4585b7f34369757d0e601623d9834) | 56,937   |
| GBTP  | whitelistClaimTokens | TRUE                        | TRUE        | [Etherscan](https://goerli.etherscan.io/tx/0x894f6b2bcc502f5d1d5221da174f0e44804cf2a382328f22bc7fe7ba403748a5) | 131,866  |

### disperseTokens

- `function disperseTokens(address[] memory accounts, uint256[] memory amounts)` (GBT)
- `function disperseTokens(address[] memory accounts, uint256[] memory amounts, bytes calldata cube3Payload)` (GBTP)

The `disperseTokens` function is an example of a function that allows a user to disperse tokens to multiple recipients, akin to a `multisend` transaction. The function was designed to showcase the impact of the increase in `calldata` size on the gas usage. The function accepts two dynamic-sized arrays, as well as the `cube3Payload`. The table displays the array lengths in parenthesis next to the function name, so `disperseTokens(20)` indicates that two arrays of length 20 were passed to the function.

| Token | Function           | Function Protection Enabled | Track Nonce | Etherscan                                                                                                      | Gas Used |
| ----- | ------------------ | --------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------- | -------- |
| GBT   | disperseTokens(5)  | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0x4d836902a0ccc653e5edc784157095c64152aaaf5fa093e17281ed449326c749) | 160,662  |
| GBT   | disperseTokens(10) | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0x5f4f7d0fc3bffc640c80b25e2d4bfffc07a853ca90cb04f46d6e14a699b3d3c4) | 288,850  |
| GBT   | disperseTokens(20) | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0x102047c7fb693765e0a43d3f7dfac8128206495109ae80f68e8297ff64310bbd) | 544,963  |
| GBTP  | disperseTokens(5)  | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0xa7f3d751aa076a6ff6b386750698b189ff113999a09ed526fa60dbd524b54aa6) | 166,191  |
| GBTP  | disperseTokens(10) | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0xf8a99a732ed249b97f76ea0ea42e88f3828a6c4dd0f6e5ca723d8b78dc666098) | 294,379  |
| GBTP  | disperseTokens(20) | FALSE                       | N/A         | [Etherscan](https://goerli.etherscan.io/tx/0x1731167b2876107a196ba35d4411aced94464e1c2df24030f9843959ecc60148) | 550,456  |
| GBTP  | disperseTokens(5)  | TRUE                        | TRUE        | [Etherscan](https://goerli.etherscan.io/tx/0xf40a0c273de8fab560777215b392cdbdb1dda107aca5dad634947877d07bbf87) | 226,275  |
| GBTP  | disperseTokens(10) | TRUE                        | TRUE        | [Etherscan](https://goerli.etherscan.io/tx/0x73a1581adf0a1b5b47533d6d51643cb73fe2f8797771403d4cae5d407b4cc1d5) | 356,161  |
| GBTP  | disperseTokens(20) | TRUE                        | FALSE       | [Etherscan](https://goerli.etherscan.io/tx/0x50a0d2551efdde9c91131b996de19ea9ec51f7e05e68da030aaa31258111ec3f) | 610,493  |
| GBTP  | disperseTokens(20) | TRUE                        | TRUE        | [Etherscan](https://goerli.etherscan.io/tx/0x3521343e4f6a505e283d12593d9701ec20ab9b51c0dfe4c3a8a3f81984938801) | 615,712  |

The difference between the `GBT` token with array lengths of `5`, and the `GBTP` token with array lengths of 5, as well as function protection and nonce-tracking enabled, is `226,275 - 160,662 = 65,613`.

The difference between the `GBT` token with array lengths of `5`, and the `GBTP` token with array lengths of 5, as well as function protection and nonce-tracking enabled, is `615,712 - 544,963 = 70,749`.

The increase in calldata size from 10 array elements to 40 array elements adds and additional `65,613 - 70,749 = 5,136` gas to the transaction.

## Development

```
forge script script/DeployERC20.s.sol:DeployERC20Script -vvvv --fork-url $GOERLI_RPC_URL --broadcast >> log_$(date +"%Y%m%d%H%M%S").txt
```
