// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24 <0.9.0;

import {console} from "lib/forge-std/src/console.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "node_modules/@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintTokenPool, TokenPool} from "lib/ccip/contracts/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {IBurnMintERC20} from "lib/ccip/contracts/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {RegistryModuleOwnerCustom} from
    "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {RateLimiter} from "lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {IRouterClient} from "lib/ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "lib/ccip/contracts/src/v0.8/ccip/libraries/Client.sol";

import {
    ERC20,
    ERC20Burnable,
    IERC20
} from
    "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from
    "lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/access/AccessControl.sol";

contract MockERC20BurnAndMintToken is IBurnMintERC20, ERC20Burnable, AccessControl {
    address internal immutable i_CCIPAdmin;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("MockERC20BurnAndMintToken", "MTK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        i_CCIPAdmin = msg.sender;
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    function burn(uint256 amount) public override(IBurnMintERC20, ERC20Burnable) onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override(IBurnMintERC20, ERC20Burnable)
        onlyRole(BURNER_ROLE)
    {
        super.burnFrom(account, amount);
    }

    function burn(address account, uint256 amount) public virtual override {
        burnFrom(account, amount);
    }

    function getCCIPAdmin() public view returns (address) {
        return i_CCIPAdmin;
    }
}

contract BurnMintPoolFork is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    MockERC20BurnAndMintToken public mockERC20TokenEthSepolia;
    MockERC20BurnAndMintToken public mockERC20TokenBaseSepolia;
    BurnMintTokenPool public burnMintTokenPoolEthSepolia;
    BurnMintTokenPool public burnMintTokenPoolBaseSepolia;

    Register.NetworkDetails public ethSepoliaNetworkDetails;
    Register.NetworkDetails public baseSepoliaNetworkDetails;

    uint256 public ethSepoliaFork;
    uint256 public baseSepoliaFork;

    address public alice;

    function setUp() public {
        alice = makeAddr("alice");

        string memory SEPOLIA_RPC = vm.envString("SEPOLIA_RPC");
        string memory BASE_SEPOLIA_RPC = vm.envString("BASE_SEPOLIA_RPC");
        ethSepoliaFork = vm.createSelectFork(SEPOLIA_RPC);
        baseSepoliaFork = vm.createFork(BASE_SEPOLIA_RPC);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // Step 1) Deploy token on Ethereum Sepolia
        vm.startPrank(alice);
        mockERC20TokenEthSepolia = new MockERC20BurnAndMintToken();
        vm.stopPrank();
        console.log("[1] mockERC20TokenEthSepolia deployed");
        // Step 2) Deploy token on Base Sepolia
        vm.selectFork(baseSepoliaFork);

        vm.startPrank(alice);
        mockERC20TokenBaseSepolia = new MockERC20BurnAndMintToken();
        vm.stopPrank();
        console.log("[2] mockERC20TokenBaseSepolia deployed");
    }

    function test_cctDeployment() public {
        // Step 3) Deploy BurnMintTokenPool on Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);
        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        address[] memory allowlist = new address[](0);
        uint8 localTokenDecimals = 18;

        vm.startPrank(alice);
        burnMintTokenPoolEthSepolia = new BurnMintTokenPool(
            IBurnMintERC20(address(mockERC20TokenEthSepolia)),
            localTokenDecimals,
            allowlist,
            ethSepoliaNetworkDetails.rmnProxyAddress,
            ethSepoliaNetworkDetails.routerAddress
        );
        vm.stopPrank();
        console.log("[3] burnMintTokenPoolEthSepolia deployed");

        // Step 4) Deploy BurnMintTokenPool on Base Sepolia
        vm.selectFork(baseSepoliaFork);
        baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        vm.startPrank(alice);
        burnMintTokenPoolBaseSepolia = new BurnMintTokenPool(
            IBurnMintERC20(address(mockERC20TokenBaseSepolia)),
            localTokenDecimals,
            allowlist,
            baseSepoliaNetworkDetails.rmnProxyAddress,
            baseSepoliaNetworkDetails.routerAddress
        );
        vm.stopPrank();
        console.log("[4] burnMintTokenPoolBaseSepolia deployed");
        // Step 5) Grant Mint and Burn roles to BurnMintTokenPool on Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);

        vm.startPrank(alice);
        mockERC20TokenEthSepolia.grantRole(mockERC20TokenEthSepolia.MINTER_ROLE(), address(burnMintTokenPoolEthSepolia));
        mockERC20TokenEthSepolia.grantRole(mockERC20TokenEthSepolia.BURNER_ROLE(), address(burnMintTokenPoolEthSepolia));
        vm.stopPrank();
        console.log("[5] mint and burn roles granted to burnMintTokenPoolEthSepolia");
        // Step 6) Grant Mint and Burn roles to BurnMintTokenPool on Base Sepolia
        vm.selectFork(baseSepoliaFork);

        vm.startPrank(alice);
        mockERC20TokenBaseSepolia.grantRole(
            mockERC20TokenBaseSepolia.MINTER_ROLE(), address(burnMintTokenPoolBaseSepolia)
        );
        mockERC20TokenBaseSepolia.grantRole(
            mockERC20TokenBaseSepolia.BURNER_ROLE(), address(burnMintTokenPoolBaseSepolia)
        );
        vm.stopPrank();
        console.log("[6] mint and burn roles granted to burnMintTokenPoolBaseSepolia");

        // Step 7) Claim Admin role on Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);

        RegistryModuleOwnerCustom registryModuleOwnerCustomEthSepolia =
            RegistryModuleOwnerCustom(ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress);

        vm.startPrank(alice);
        registryModuleOwnerCustomEthSepolia.registerAdminViaGetCCIPAdmin(address(mockERC20TokenEthSepolia));
        vm.stopPrank();
        console.log("[7] Claim Admin role on Ethereum Sepolia");

        // Step 8) Claim Admin role on Base Sepolia
        vm.selectFork(baseSepoliaFork);

        RegistryModuleOwnerCustom registryModuleOwnerCustomBaseSepolia =
            RegistryModuleOwnerCustom(baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress);

        vm.startPrank(alice);
        registryModuleOwnerCustomBaseSepolia.registerAdminViaGetCCIPAdmin(address(mockERC20TokenBaseSepolia));
        vm.stopPrank();
        console.log("[8] Claim Admin role on Base Sepolia");
        // Step 9) Accept Admin role on Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);

        TokenAdminRegistry tokenAdminRegistryEthSepolia =
            TokenAdminRegistry(ethSepoliaNetworkDetails.tokenAdminRegistryAddress);

        vm.startPrank(alice);
        tokenAdminRegistryEthSepolia.acceptAdminRole(address(mockERC20TokenEthSepolia));
        vm.stopPrank();
        console.log("[9] Accept Admin role on Ethereum Sepolia");
    
        // Step 10) Accept Admin role on Base Sepolia
        vm.selectFork(baseSepoliaFork);

        TokenAdminRegistry tokenAdminRegistryBaseSepolia =
        TokenAdminRegistry(baseSepoliaNetworkDetails.tokenAdminRegistryAddress);

        vm.startPrank(alice);
        tokenAdminRegistryBaseSepolia.acceptAdminRole(address(mockERC20TokenBaseSepolia));
        vm.stopPrank();
        console.log("[10] Accept Admin role on Base Sepolia");
        // Step 11) Link token to pool on Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);

        vm.startPrank(alice);
        tokenAdminRegistryEthSepolia.setPool(address(mockERC20TokenEthSepolia), address(burnMintTokenPoolEthSepolia));
        vm.stopPrank();
        console.log("[11] Link token to pool on Ethereum Sepolia");

        // Step 12) Link token to pool on Base Sepolia
        vm.selectFork(baseSepoliaFork);

        vm.startPrank(alice);
        tokenAdminRegistryBaseSepolia.setPool(address(mockERC20TokenBaseSepolia), address(burnMintTokenPoolBaseSepolia));
        vm.stopPrank();
        console.log("[12] Link token to pool on Base Sepolia");

        // Step 13) Configure Token Pool on Ethereum Sepolia
        vm.selectFork(ethSepoliaFork);

        vm.startPrank(alice);
        TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
        bytes[] memory remotePoolAddressesEthSepolia = new bytes[](1);
        remotePoolAddressesEthSepolia[0] = abi.encode(address(burnMintTokenPoolEthSepolia));
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: baseSepoliaNetworkDetails.chainSelector,
            remotePoolAddresses: remotePoolAddressesEthSepolia,
            remoteTokenAddress: abi.encode(address(mockERC20TokenBaseSepolia)),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: true, capacity: 100_000, rate: 167}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: true, capacity: 100_000, rate: 167})
        });
        uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);
        burnMintTokenPoolEthSepolia.applyChainUpdates(remoteChainSelectorsToRemove, chains);
        vm.stopPrank();
        console.log("[13] Configured Token Pool on Ethereum Sepolia");

        // Step 14) Configure Token Pool on Base Sepolia
        vm.selectFork(baseSepoliaFork);

        vm.startPrank(alice);
        chains = new TokenPool.ChainUpdate[](1);
        bytes[] memory remotePoolAddressesBaseSepolia = new bytes[](1);
        remotePoolAddressesBaseSepolia[0] = abi.encode(address(burnMintTokenPoolEthSepolia));
        chains[0] = TokenPool.ChainUpdate({
            remoteChainSelector: ethSepoliaNetworkDetails.chainSelector,
            remotePoolAddresses: remotePoolAddressesBaseSepolia,
            remoteTokenAddress: abi.encode(address(mockERC20TokenEthSepolia)),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: true, capacity: 100_000, rate: 167}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: true, capacity: 100_000, rate: 167})
        });
        burnMintTokenPoolBaseSepolia.applyChainUpdates(remoteChainSelectorsToRemove, chains);
        vm.stopPrank();
        console.log("[14] Configured Token Pool on Base Sepolia");

        // Step 15) Mint tokens on Ethereum Sepolia and transfer them to Base Sepolia
        vm.selectFork(ethSepoliaFork);

        address linkSepolia = ethSepoliaNetworkDetails.linkAddress;
        ccipLocalSimulatorFork.requestLinkFromFaucet(address(alice), 20 ether);

        uint256 amountToSend = 100;
        Client.EVMTokenAmount[] memory tokenToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount =
            Client.EVMTokenAmount({token: address(mockERC20TokenEthSepolia), amount: amountToSend});
        tokenToSendDetails[0] = tokenAmount;

        vm.startPrank(alice);
        mockERC20TokenEthSepolia.mint(address(alice), amountToSend);

        mockERC20TokenEthSepolia.approve(ethSepoliaNetworkDetails.routerAddress, amountToSend);
        IERC20(linkSepolia).approve(ethSepoliaNetworkDetails.routerAddress, 20 ether);

        uint256 balanceOfAliceBeforeEthSepolia = mockERC20TokenEthSepolia.balanceOf(alice);

        IRouterClient routerEthSepolia = IRouterClient(ethSepoliaNetworkDetails.routerAddress);
        routerEthSepolia.ccipSend(
            baseSepoliaNetworkDetails.chainSelector,
            Client.EVM2AnyMessage({
                receiver: abi.encode(address(alice)),
                data: "",
                tokenAmounts: tokenToSendDetails,
                extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0})),
                feeToken: linkSepolia
            })
        );

        uint256 balanceOfAliceAfterEthSepolia = mockERC20TokenEthSepolia.balanceOf(alice);
        vm.stopPrank();
        console.log("[15] minted and sent tokens from Ethereum Sepolia to Base Sepolia");

        assertEq(balanceOfAliceAfterEthSepolia, balanceOfAliceBeforeEthSepolia - amountToSend);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseSepoliaFork);

        uint256 balanceOfAliceAfterBaseSepolia = mockERC20TokenBaseSepolia.balanceOf(alice);
        assertEq(balanceOfAliceAfterBaseSepolia, amountToSend);
        console.log("[16] received tokens in Base Sepolia");
    }
}