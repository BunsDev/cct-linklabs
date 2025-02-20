# FAQs

### What's the Cross-Chain Token Standard?
Chainlink's Cross-Chain Token (CCT) standard is a framework introduced with the [CCIP v1.5 upgrade](https://docs.chain.link/v1.5/concepts/cross-chain-token-standard) that enables token developers to create tokens that can be securely and seamlessly transferred across different blockchains. It allows both new and existing tokens to be integrated with Chainlink's Cross-Chain Interoperability Protocol (CCIP) in a self-service manner, simplifying the management and transfer of tokens across various blockchain ecosystems. CCTs are designed to maintain consistent liquidity and functionality regardless of the chain being used.

### What problems does the CCT Standard solve?
The CCT standard addresses two main challenges in the multi-chain environment: liquidity fragmentation and the lack of autonomy for token developers. Liquidity fragmentation occurs when assets are isolated on individual blockchains, making it difficult to access liquidity across different ecosystems. CCT solves this by enabling tokens to move seamlessly across multiple blockchains without fragmenting liquidity. It also empowers projects to enable their tokens for cross-chain operations without relying on third parties, providing a self-service model that allows rapid expansion to other blockchains supported by CCIP.

### What are the key benefits of using the CCT Standard?
- **Self-Service and Permissionless Deployment**: Token developers can launch or enable cross-chain tokens within minutes.
- **Developer Control and Flexibility**: Token developers retain full ownership of their token contracts, token pools, and implementation logic, including rate limits.
- **Programmable Token Transfers**: CCIP allows the transfer of value along with data, enabling complex cross-chain instructions.
- **Token Developer Attestation**: An optional layer of verification where token developers can attest to token burn or lock events before minting or unlocking on destination chains.
- **Defense-in-Depth Security**: CCTs are secured by Chainlink CCIP, leveraging decentralized oracle networks and a Risk Management Network.
- **No Liquidity Pools Required**: Token pools can operate without the need for liquidity, reducing upfront capital requirements.
- **Zero-Slippage Transfers**: Ensures the exact amount of tokens sent is received on the destination chain.
- **Zero-downtime upgrades**: Token pools support seamless transitions between pool versions while maintaining support for in-flight messages

### What is a Token Pool and what are the different types?
A token pool is an abstraction layer over ERC-20 tokens that facilitates token-related operations for cross-chain transfers. It manages how tokens are locked, burned, minted, or unlocked across blockchains. Token pools include rate limits as a security feature. 

**There are two types of token pools**:
- **BurnMintTokenPool**: Burns tokens on the source blockchain and mints an equivalent amount on the destination blockchain.
- **LockReleaseTokenPool**: Locks tokens on the source blockchain and unlocks tokens on the destination blockchain.

### What are the requirements for a token to be compatible with the CCT Standard?
The requirements for a token smart contract to be CCT-compatible depend on the token handling mechanism used. For the Burn & Mint mechanism, the token smart contract must have the following functions:
- **mint(address account, uint256 amount)**: Mints tokens on the destination blockchain.
- **burn(uint256 amount)**: Burns tokens on the source blockchain.
- **decimals()**: Returns the token's number of decimals.
- **balanceOf(address account)**: Returns the current token balance of the specified account.
- **burnFrom(address account, uint256 amount)**: (Optional) Burns tokens from a specified account on the source blockchain.

For the Lock & Mint mechanism, the token smart contract must have the following functions:
- **decimals()**: Returns the token's number of decimals.
- **balanceOf(address account)**: Returns the current token balance of the specified account.
- **Must support granting mint and burn permissions to the token pool on the destination blockchain.

### How do I deploy a Cross-Chain Token (CCT)?
You can deploy a CCT using tools like Remix IDE or Thirdweb. The process involves:
- Deploying a token contract on each blockchain.
- Deploying token pools on each blockchain.
- Configuring the token contracts to allow the pools to mint and burn tokens.
- Linking the token to the pool on each blockchain.
- Configuring the token pools to communicate with each other, specifying the remote chain and pool addresses.

Several tutorials and code examples are available to guide you through each step, including those provided by Chainlink and Thirdweb.

### How are Rate Limits used in CCT?
Rate limits are used to control the rate at which tokens can be transferred across chains, serving as a security feature. Token developers can configure both inbound and outbound rate limits for each token pool. The rate limit admin (or the pool owner if no rate limit admin is set) can adjust these limits using the setChainRateLimiterConfig function to prevent excessive token transfers or overload of the token pool.

### What are some considerations when handling tokens with different decimal places across blockchains?

When deploying tokens with different decimal places across blockchains, it's important to be aware of potential precision loss during cross-chain transfers. If the source chain has higher precision than the destination chain, rounding may occur, leading to a loss of tokens. Deploying tokens with the same number of decimals across all blockchains is the recommended best practice.

If different decimals must be used due to blockchain limitations, be prepared to handle lost tokens from high to low precision transfers:
- **Burn/mint pools**: Lost precision results in permanently burned tokens
- **Lock/release pools**: Lost precision results in tokens accumulating in the source pool.


### Additional Resources
- [CCIP Documentation](https://docs.chain.link/ccip)
- [CCT Standard Implementation Guide](https://cct.wiki)
- [Token Manager](https://tokenmanager.chain.link)
- [CCT Standard Tutorials](https://docs.chain.link/ccip/tutorials/token-manager)
- [CCIP Directory](https://docs.chain.link/ccip/directory)
- [Token Manager (testnet)](https://test.tokenmanager.chain.link)