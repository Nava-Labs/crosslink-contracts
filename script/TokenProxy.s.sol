pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./CCIPHelper.sol";
import {BridgedCrosslink} from "../src/token/BridgedCrosslink.sol";
import {TokenProxy_Source} from "../src/proxy/TokenProxy_Source.sol";
import {SimpleERC20} from "../src/token/SimpleERC20.sol";

contract DeployTokenProxySourceAsSourceInSepolia is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

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

contract DeployBridgedCrosslinkAsDestinationInOPGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged Cross Link";
        string memory symbol = "BCL";
        uint64 chainIdOPGoerli = 2664363617261496610;

       BridgedCrosslink _bridgedCrosslink = new BridgedCrosslink(
            name,
            symbol,
            router,
            chainIdOPGoerli
        );

        console.log(
            "Bridged Crosslink in OP Goerli deployed with address: ",
            address(_bridgedCrosslink)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCrosslinkAsDestinationInFuji is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged Cross Link";
        string memory symbol = "BCL";
        uint64 chainIdFuji = 14767482510784806043;

       BridgedCrosslink _bridgedCrosslink = new BridgedCrosslink(
            name,
            symbol,
            router,
            chainIdFuji
        );

        console.log(
            "Bridged Crosslink in AV Fuji deployed with address: ",
            address(_bridgedCrosslink)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCrosslinkAsDestinationInArbitrumGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged Cross Link";
        string memory symbol = "BCL";
        uint64 chainIdArbitrumGoerli = 6101244977088475029;

       BridgedCrosslink _bridgedCrosslink = new BridgedCrosslink(
            name,
            symbol,
            router,
            chainIdArbitrumGoerli
        );

        console.log(
            "Bridged Crosslink in Arbitrum Goerli deployed with address: ",
            address(_bridgedCrosslink)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCrosslinkAsDestinationInPolygonMumbai is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged Cross Link";
        string memory symbol = "BCL";
        uint64 chainIdPolygonMumbai = 12532609583862916517;

       BridgedCrosslink _bridgedCrosslink = new BridgedCrosslink(
            name,
            symbol,
            router,
            chainIdPolygonMumbai
        );

        console.log(
            "Bridged Crosslink in Polygon Mumbai deployed with address: ",
            address(_bridgedCrosslink)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCrosslinkAsDestinationInBaseGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged Cross Link";
        string memory symbol = "BCL";
        uint64 chainIdBaseGoerli = 5790810961207155433;

       BridgedCrosslink _bridgedCrosslink = new BridgedCrosslink(
            name,
            symbol,
            router,
            chainIdBaseGoerli
        );

        console.log(
            "Bridged Crosslink in Base Goerli deployed with address: ",
            address(_bridgedCrosslink)
        );

        vm.stopBroadcast();
    }
}

contract DeployBridgedCrosslinkAsDestinationInBSCTestnet is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Bridged Cross Link";
        string memory symbol = "BCL";
        uint64 chainIdBaseGoerli = 13264668187771770619;

       BridgedCrosslink _bridgedCrosslink = new BridgedCrosslink(
            name,
            symbol,
            router,
            chainIdBaseGoerli
        );

        console.log(
            "Bridged Crosslink in Base Goerli deployed with address: ",
            address(_bridgedCrosslink)
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

        // Use this if its Crosslink
        // Crosslink(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

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

        // Use this if its BridgedCrosslink
        BridgedCrosslink(tokenProxy).burnAndMintOrUnlock(bestRoutes, tokenReceiver, amount);

        vm.stopBroadcast();
    }
}