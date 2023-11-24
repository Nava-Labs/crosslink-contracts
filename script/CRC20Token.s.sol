pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./CCIPHelper.sol";
import {CRC20Example} from "../src/examples/token/CRC20Example.sol";
import {CRC20Source} from "../src/ccip/CRC20/CRC20Source.sol";
import {SimpleERC20} from "../src/mocks/SimpleERC20.sol";

contract DeployCRC20SourceInSepolia is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        uint64 chainIdSepolia = 16015286601757825753;
        address tokenAddress = 0x20AF34a33637C2c1671E071Dba89FB68f4403334;

        CRC20Source crcSource = new CRC20Source(
           tokenAddress,
           router,
           chainIdSepolia
        );

        console.log(
            "CRC20Source Source in sepolia deployed with address: ",
            address(crcSource)
        );

        vm.stopBroadcast();
    }
}

contract DeployCRC20TokenExampleInOPGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Cross Chain ETH";
        string memory symbol = "ccipETH";
        uint64 chainIdOPGoerli = 2664363617261496610;

       CRC20Example _CRC20Example = new CRC20Example(
            name,
            symbol,
            router,
            chainIdOPGoerli
        );

        console.log(
            "Bridged Crosslink in OP Goerli deployed with address: ",
            address(_CRC20Example)
        );

        vm.stopBroadcast();
    }
}

contract DeployCRC20TokenExampleInFuji is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Cross Chain ETH";
        string memory symbol = "ccipETH";
        uint64 chainIdFuji = 14767482510784806043;

       CRC20Example _CRC20Example = new CRC20Example(
            name,
            symbol,
            router,
            chainIdFuji
        );

        console.log(
            "Bridged Crosslink in AV Fuji deployed with address: ",
            address(_CRC20Example)
        );

        vm.stopBroadcast();
    }
}

contract DeployCRC20TokenExampleInArbitrumGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Cross Chain ETH";
        string memory symbol = "ccipETH";
        uint64 chainIdArbitrumGoerli = 6101244977088475029;

       CRC20Example _CRC20Example = new CRC20Example(
            name,
            symbol,
            router,
            chainIdArbitrumGoerli
        );

        console.log(
            "Bridged Crosslink in Arbitrum Goerli deployed with address: ",
            address(_CRC20Example)
        );

        vm.stopBroadcast();
    }
}

contract DeployCRC20TokenExampleInPolygonMumbai is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Cross Chain ETH";
        string memory symbol = "ccipETH";
        uint64 chainIdPolygonMumbai = 12532609583862916517;

       CRC20Example _CRC20Example = new CRC20Example(
            name,
            symbol,
            router,
            chainIdPolygonMumbai
        );

        console.log(
            "Bridged Crosslink in Polygon Mumbai deployed with address: ",
            address(_CRC20Example)
        );

        vm.stopBroadcast();
    }
}

contract DeployCRC20TokenExampleInBaseGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Cross Chain ETH";
        string memory symbol = "ccipETH";
        uint64 chainIdBaseGoerli = 5790810961207155433;

       CRC20Example _CRC20Example = new CRC20Example(
            name,
            symbol,
            router,
            chainIdBaseGoerli
        );

        console.log(
            "Bridged Crosslink in Base Goerli deployed with address: ",
            address(_CRC20Example)
        );

        vm.stopBroadcast();
    }
}

contract DeployCRC20TokenExampleInBSCTestnet is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , ,) = getConfigFromNetwork(chain);

        string memory name = "Cross Chain ETH";
        string memory symbol = "ccipETH";
        uint64 chainIdBaseGoerli = 13264668187771770619;

       CRC20Example _CRC20Example = new CRC20Example(
            name,
            symbol,
            router,
            chainIdBaseGoerli
        );

        console.log(
            "Bridged Crosslink in Base Goerli deployed with address: ",
            address(_CRC20Example)
        );

        vm.stopBroadcast();
    }
}

contract UpdateCrossChainAppCRC20Source is Script, CCIPHelper {
    function run(address payable marketplace, uint64[] memory chainSelector, address[] memory crossChainAppAddress) external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Use this if its CRC20Source
        CRC20Source(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

        vm.stopBroadcast();
    }
}

contract UpdateCrossChainAppCRC20TokenExample is Script, CCIPHelper {
    function run(address payable marketplace, uint64[] memory chainSelector, address[] memory crossChainAppAddress) external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Use this if its CRC20Source
        CRC20Example(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

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

contract SendCRC20SourceToAnotherChain is Script, CCIPHelper{
    function run(address payable crc20Source, uint64[] memory bestRoutes, address tokenReceiver, uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CRC20Source(crc20Source).lockAndMint(bestRoutes, tokenReceiver, amount);

        vm.stopBroadcast();
    }
}

contract SendCRC20TokenToAnotherChain is Script, CCIPHelper{
    function run(address payable crc20Token, uint64[] memory bestRoutes, address tokenReceiver, uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CRC20Example(crc20Token).burnAndMintOrUnlock(bestRoutes, tokenReceiver, amount);

        vm.stopBroadcast();
    }
}

contract SendCRC20TokenToTesterAddress is Script, CCIPHelper{
    function run(address token,address to,uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC20(token).transfer(to, amount);

        vm.stopBroadcast();
    }
}