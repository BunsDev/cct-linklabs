_This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

# Building C

Demonstrating how to use Chainlink Cross-Chain Interoperobility Protocol (CCIP) leveraging the Cross Chain Token (CCT) Standard to send a token from Ethereum Sepolia to Base Sepolia. This includes the creation of a CCT on the source chain, and the redemption of that CCT on the destination chain and management of the CCT via the sdk and token manager.
# Getting Started

In the next section you can see how to send data from one chain to another. But before that, you need to set up some environment variables, install dependencies, setup environment variables, and compile contracts.

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

## **4. Deploy Token Contracts**

<!-- ### **Contract Design** -->

<!-- ![cct-process](./img/cct-process.png) -->

Before we proceed with deployment, it is best practice to run tests, which can be executed as follows:

```bash
forge test --match-contract SenderTest -vv
```

```bash
forge test --match-contract ReceiverTest -vv
```

### Deployment Scripts
**In order to interact with our contracts, we first need to deploy them, which is simplified in the [`script/Deploy.s.sol`](./script/Deploy.s.sol) smart contract, so let's deploy each contract applying the deployment script for each of the following commands.**

#### [`TokenSender.sol`](./src/TokenSender.sol) via [`Deploy.s.sol`](./script/Deploy.s.sol#L10)

```bash
forge script ./script/Deploy.s.sol:DeploySender -vvv --broadcast --rpc-url ethSepolia
```


----



Update `MESSAGE_SENDER_ADDRESS` stored in your .env, then make sure to verify the deployment by running the following command:

```bash
export MESSAGE_SENDER_ADDRESS=$(grep MESSAGE_SENDER_ADDRESS .env | cut -d '=' -f2)

forge verify-contract $MESSAGE_SENDER_ADDRESS src/MessageSender.sol:MessageSender \
--rpc-url 'https://eth-sepolia.public.blastapi.io' \
--verifier blockscout \
--verifier-url 'https://eth-sepolia.blockscout.com/api/'

echo "Verified MessageSender contract may be found here: https://eth-sepolia.blockscout.com/address/$MESSAGE_SENDER_ADDRESS?tab=contract"
```

**Finally, since the MessageSender requires funds to pay for fees, we will load up the contract programatically, as follows with 0.05 ETH:**

```bash
KEYSTORE=$(grep KEYSTORE .env | cut -d '=' -f2)

cast send $MESSAGE_SENDER_ADDRESS --rpc-url ethereumSepolia --value 0.05ether --keystore $KEYSTORE
```

#### [`MessageReceiver.sol`](./src/MessageReceiver.sol) via [`Deploy.s.sol`](./script/Deploy.s.sol#L49)

```bash
forge script ./script/Deploy.s.sol:DeployReceiver -vvv --broadcast --rpc-url baseSepolia
```

Update `MESSAGE_RECEIVER_ADDRESS` stored in your .env, then make sure to verify the deployment by running the following command:

```bash
export MESSAGE_RECEIVER_ADDRESS=$(grep MESSAGE_RECEIVER_ADDRESS .env | cut -d '=' -f2)

forge verify-contract $MESSAGE_RECEIVER_ADDRESS src/MessageReceiver.sol:MessageReceiver --etherscan-api-key 'verifyContract' \
&& orge verify-contract $MESSAGE_RECEIVER_ADDRESS src/MessageReceiver.sol:MessageReceiver \
--rpc-url 'https://subnets.avax.network/dispatch/testnet/rpc' \
--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/779672/etherscan' \

echo "Verified MessageReceiver contract may be found here: https://779672.testnet.snowtrace.io/address/$MESSAGE_RECEIVER_ADDRESS/contract/779672/code"
```