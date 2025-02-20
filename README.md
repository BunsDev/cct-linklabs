_This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

# Building with the Cross Chain Token (CCT) Standard

Demonstrating how to use Chainlink Cross-Chain Interoperobility Protocol (CCIP) leveraging the Cross Chain Token (CCT) Standard to send a token from Ethereum Sepolia to Base Sepolia. This includes the creation of a CCT on the source chain, and the redemption of that CCT on the destination chain and management of the CCT via the sdk and token manager.

# Getting Started

In the next section you can see how to send data from one chain to another. But before that, you need to set up some environment variables, install dependencies, setup environment variables, and compile contracts.

![cct-process](https://raw.githubusercontent.com/smartcontractkit/ccip-starter-kit-foundry/refs/heads/main/img/basic-architecture.png)


## **1. Install Dependencies**

```bash
yarn && make
```

## **2. Setup Environment**

Run the command below, then update the .env `PRIVATE_KEY` and `ETHERSCAN_API_KEY` variables.

```bash
if [ -f .env ]; then
    echo "We will use the .env your have already created."
    else
    if [ -z "${DOTENV}" ]; then
        echo "Creating and setting .env"
        cp .env.example .env && source .env
        echo "Set your PRIVATE_KEY and ETHERSCAN_API_KEY in .env"
    fi
fi
```

## **3. Create Wallet**

To create a new wallet that is stored in a keystore, issue the following command, which will prompt you to secure the private key with a password.

```bash
# Grabs the PRIVATE_KEY from the .env file.
PRIVATE_KEY=$(grep PRIVATE_KEY .env | cut -d '=' -f2)

if [ -f keystore/secret ]; then
    echo "Found keystore in workspace"
    else
    if [ -z "${DOTENV}" ]; then
        echo "Creating and setting keystore"
        mkdir keystore
        cast wallet import --private-key $PRIVATE_KEY -k keystore secret
        echo "keystore/secret created"
    fi
fi

```

For ease use of the keystore we already configured a environment variable called `KEYSTORE` pointing to the `keystore` file in the working directory.

You can use the wallet stored in the keystore by adding the `--keystore` flag instead of the `--private-key` flag. Run the command below to confirm your wallet address is stored accurately.

```bash
KEYSTORE=$(grep KEYSTORE .env | cut -d '=' -f2)

cast wallet address --keystore $KEYSTORE
```

## **4. Test Contracts**

Before we proceed with deployment, it is best practice to run tests, which can be executed as follows:

```bash
forge test -vvv
```

```plaintext
[PASS] test_cctDeployment() (gas: 7404836)
Logs:
  [1] mockERC20TokenEthSepolia deployed
  [2] mockERC20TokenBaseSepolia deployed
  [3] burnMintTokenPoolEthSepolia deployed
  [4] burnMintTokenPoolBaseSepolia deployed
  [5] mint and burn roles granted to burnMintTokenPoolEthSepolia
  [6] mint and burn roles granted to burnMintTokenPoolBaseSepolia
  [7] Claim Admin role on Ethereum Sepolia
  [8] Claim Admin role on Base Sepolia
  [9] Accept Admin role on Ethereum Sepolia
  [10] Accept Admin role on Base Sepolia
  [11] Link token to pool on Ethereum Sepolia
  [12] Link token to pool on Base Sepolia
  [13] Configured Token Pool on Ethereum Sepolia
  [14] Configured Token Pool on Base Sepolia
  [15] minted and sent tokens from Ethereum Sepolia to Base Sepolia
  [16] received tokens in Base Sepolia
```

### Deployment Scripts
In order to interact with our contracts, we first need to deploy them, which is simplified in the [`script/deploy`](./script/deploy) smart contracts, so let's deploy each contract applying the deployment script for each of the following commands.

<!-- ```bash
forge script ./script/deploy/DeployTokens.s.sol:DeployToken -vvv --broadcast --rpc-url ethereumSepolia
```

```bash
forge script ./script/deploy/DeployBurnMintTokenPool.s.sol:DeployBurnMintTokenPool -vvv --broadcast --rpc-url baseSepolia
```

## **5. Set Pool**

```bash
forge script ./script/manage/SetPool.s.sol:SetPool -vvv --broadcast --rpc-url baseSepolia
```

## **6. Mint Tokens**

```bash
forge script ./script/mint/MintTokens.s.sol:MintTokens -vvv --broadcast --rpc-url ethereumSepolia
``` -->
