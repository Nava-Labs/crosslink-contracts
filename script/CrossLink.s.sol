// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./CCIPHelper.sol";
import {CrossLinkMarketplace} from "../src/marketplace/CrossLinkMarketplace.sol";

contract DeployCrossLinkSepolia is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(chain);

        uint64 chainIdThis = 16015286601757825753;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployCrossLinkOpGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(chain);

        uint64 chainIdThis = 2664363617261496610;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployCrossLinkFuji is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(chain);

        uint64 chainIdThis = 14767482510784806043;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployCrossLinkArbitrumGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(chain);

        uint64 chainIdThis = 6101244977088475029;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployCrossLinkPolygonMumbai is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(chain);

        uint64 chainIdThis = 12532609583862916517;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}
