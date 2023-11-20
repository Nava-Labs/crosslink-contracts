pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./CCIPHelper.sol";
import {BridgedCoffee} from "../src/token/BridgedCoffee.sol";
import {TokenProxy_Source} from "../src/proxy/TokenProxy_Source.sol";
import {SimpleERC20} from "../src/token/SimpleERC20.sol";

contract DeployTokenProxySourceAsSourceInSepolia is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        
        console.log(router);
        uint64 chainIdSepolia = 16015286601757825753;
        address tokenAddress = 0xe317A28EceC92f5FeF03d4F9Cd37f291AB5672D2;

        TokenProxy_Source _tokenProxy_Source = new TokenProxy_Source(
           tokenAddress,
           router,
           chainIdSepolia
        );

        console.log(
            "TokenProxy Source in sepolia deployed with address: ",
            address(_tokenProxy_Source)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCoffeeAsDestinationInOPGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged COFFEE";
        string memory symbol = "BisCoff";
        console.log(router);
        uint64 chainIdOPGoerli = 2664363617261496610;


        BridgedCoffee _bridgedCoffee = new BridgedCoffee(
            name,
            symbol,
            router,
            chainIdOPGoerli
        );

        console.log(
            "Bridged Coffee in OP Goerli deployed with address: ",
            address(_bridgedCoffee)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCoffeeAsDestinationInFuji is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged COFFEE";
        string memory symbol = "BisCoff";
        console.log(router);
        uint64 chainIdFuji = 14767482510784806043;


        BridgedCoffee _bridgedCoffee = new BridgedCoffee(
            name,
            symbol,
            router,
            chainIdFuji
        );

        console.log(
            "Bridged Coffee in AV Fuji deployed with address: ",
            address(_bridgedCoffee)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCoffeeAsDestinationInArbitrumGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged COFFEE";
        string memory symbol = "BisCoff";
        console.log(router);
        uint64 chainIdArbitrumGoerli = 6101244977088475029;


        BridgedCoffee _bridgedCoffee = new BridgedCoffee(
            name,
            symbol,
            router,
            chainIdArbitrumGoerli
        );

        console.log(
            "Bridged Coffee in Arbitrum Goerli deployed with address: ",
            address(_bridgedCoffee)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCoffeeAsDestinationInPolygonMumbai is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged COFFEE";
        string memory symbol = "BisCoff";
        console.log(router);
        uint64 chainIdPolygonMumbai = 12532609583862916517;


        BridgedCoffee _bridgedCoffee = new BridgedCoffee(
            name,
            symbol,
            router,
            chainIdPolygonMumbai
        );

        console.log(
            "Bridged Coffee in Polygon Mumbai deployed with address: ",
            address(_bridgedCoffee)
        );

        vm.stopBroadcast();
    }
}

contract UpdateCrossChainApp is Script, CCIPHelper {
    function run(address payable marketplace, uint64[] memory chainSelector, address[] memory crossChainAppAddress) external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Use this if its TokenProxy_Source
        TokenProxy_Source(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

        // Use this if its BridgedCoffee
        // BridgedCoffee(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

        vm.stopBroadcast();
    }
}

contract DistributeLink is Script, CCIPHelper {
    function run(SupportedNetworks network, address to, uint256 amount) external {
        (, address link, , ) = getConfigFromNetwork(network);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC20(link).transfer(to, amount);

        vm.stopBroadcast();
    }
}

contract SendTokenBridgeToAnotherChain is Script, CCIPHelper{
    function run(address payable tokenProxy, uint64[] memory bestRoutes, address tokenReceiver, uint256 amount) external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Use this if its TokenProxy_Source
        // TokenProxy_Source(tokenProxy).lockAndMint(bestRoutes, tokenReceiver, amount);

        // Use this if its BridgedCoffee
        BridgedCoffee(tokenProxy).burnAndMintOrUnlock(bestRoutes, tokenReceiver, amount);

        vm.stopBroadcast();
    }
}