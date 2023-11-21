// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./CCIPHelper.sol";
import {CrossLinkMarketplace} from "../src/marketplace/CrossLinkMarketplace.sol";
import {SimpleERC20} from "../src/token/SimpleERC20.sol";
import {console2} from "forge-std/Test.sol";

contract DeployCrossLinkSepolia is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ) = getConfigFromNetwork(chain);
        address _tokenPayment = 0xA364E5A4D3F7Bf47Bcaa135634dFe1e47B2c57b8;

        uint64 chainIdThis = 16015286601757825753;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
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

        (address router, , , ) = getConfigFromNetwork(chain);
        address _tokenPayment = 0x7794DECEb421974aD5f61Cd04699715CAeb10638;

        uint64 chainIdThis = 2664363617261496610;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
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

        (address router, , , ) = getConfigFromNetwork(chain);
                address _tokenPayment = 0x48156d3EA56bb4F120b1a942Cea061AbbA9fb989;

        uint64 chainIdThis = 14767482510784806043;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
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

        (address router, , , ) = getConfigFromNetwork(chain);
                address _tokenPayment = address(0);


        uint64 chainIdThis = 6101244977088475029;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
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

        (address router, , , ) = getConfigFromNetwork(chain);
                address _tokenPayment = address(0);


        uint64 chainIdThis = 12532609583862916517;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployCrossLinkBaseGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ) = getConfigFromNetwork(chain);
        address _tokenPayment = address(0);
        
        uint64 chainIdThis = 5790810961207155433;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployCrossLinkBscTestnet is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ) = getConfigFromNetwork(chain);
        address _tokenPayment = 0x7794DECEb421974aD5f61Cd04699715CAeb10638;
        
        uint64 chainIdThis = 13264668187771770619;
        uint64 chainIdMaster = 16015286601757825753;

        CrossLinkMarketplace _marketplace = new CrossLinkMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "CrossLink contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}


contract UpdateCrossChainApp is Script, CCIPHelper {
    function run(address payable marketplace, uint64[] memory chainSelector, address[] memory crossChainAppAddress) external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CrossLinkMarketplace(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

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

contract Marketplace is Script, CCIPHelper {
    function listing(address payable to, address tokenAddress, uint256 tokenId, uint256 price) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CrossLinkMarketplace(to).listing(tokenAddress, tokenId, price);

        vm.stopBroadcast();
    }

    function buy(address payable to, CrossLinkMarketplace.SaleType saleType, uint64[] memory bestRoutes, address tokenAddress, uint256 tokenId) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CrossLinkMarketplace(to).buy(saleType, bestRoutes, tokenAddress, tokenId);

        vm.stopBroadcast();
    }

}
