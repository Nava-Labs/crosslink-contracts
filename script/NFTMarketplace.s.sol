// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./CCIPHelper.sol";
import {NFTMarketplace} from "../src/examples/app/NFTMarketplace.sol";
import {SimpleERC20} from "../src/mocks/SimpleERC20.sol";
import {console2} from "forge-std/Test.sol";

contract DeployMarketplaceSepolia is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , , ) = getConfigFromNetwork(chain);
        address _tokenPayment = 0xeB21Ad3953eDB8228a50E4f0FcD6A1F6391b38e7;

        uint64 chainIdThis = 16015286601757825753;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployMarketplaceOpGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , , ) = getConfigFromNetwork(chain);
        address _tokenPayment = 0x84Ca5978286e5c49152424d68101B07465a89D53;

        uint64 chainIdThis = 2664363617261496610;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployMarketplaceFuji is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , , ) = getConfigFromNetwork(chain);
                address _tokenPayment = 0x6B13990cf43D2Abfe785AB7De89067653BACbeF3;

        uint64 chainIdThis = 14767482510784806043;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployMarketplaceArbitrumGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ,) = getConfigFromNetwork(chain);
        address _tokenPayment = address(0);


        uint64 chainIdThis = 6101244977088475029;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployMarketplacePolygonMumbai is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ,) = getConfigFromNetwork(chain);
                address _tokenPayment = address(0);


        uint64 chainIdThis = 12532609583862916517;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployMarketplaceBaseGoerli is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ,) = getConfigFromNetwork(chain);
        address _tokenPayment = 0x4C4b43A82fb9222E8505FBf6030D1F6D92a6ff9C;
        
        uint64 chainIdThis = 5790810961207155433;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}

contract DeployMarketplaceBscTestnet is Script, CCIPHelper {
    function run(SupportedNetworks chain) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, , , ,) = getConfigFromNetwork(chain);
        address _tokenPayment = 0xa23C69E42a8CBf7270cFAE05B6079A07B47C5612;
        
        uint64 chainIdThis = 13264668187771770619;
        uint64 chainIdMaster = 16015286601757825753;

        NFTMarketplace _marketplace = new NFTMarketplace (
            chainIdThis,
            chainIdMaster,
            router,
            _tokenPayment
        );

        console.log(
            "Marketplace contract deployed on with address: ",
            address(_marketplace)
        );

        vm.stopBroadcast();
    }
}


contract UpdateCrossChainApp is Script, CCIPHelper {
    function run(address payable marketplace, uint64[] memory chainSelector, address[] memory crossChainAppAddress) external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTMarketplace(marketplace).updateCrossChainApp(chainSelector, crossChainAppAddress);

        vm.stopBroadcast();
    }
}

contract DistributeLink is Script, CCIPHelper {
    function run(SupportedNetworks network, address to, uint256 amount) external {
        (, address link, , , ) = getConfigFromNetwork(network);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC20(link).transfer(to, amount);

        vm.stopBroadcast();
    }
}

contract WithdrawLink is Script, CCIPHelper {
    function run(SupportedNetworks network, address payable to, address beneficiary) external {
        (, address link, , , ) = getConfigFromNetwork(network);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTMarketplace(to).withdrawToken(beneficiary, link);

        vm.stopBroadcast();
    }
}

contract Marketplace is Script, CCIPHelper {
    function listing(address payable to, address tokenAddress, uint256 tokenId, uint256 price) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTMarketplace(to).listing(tokenAddress, tokenId, price);

        vm.stopBroadcast();
    }

    function buy(address payable to, uint64[] memory bestRoutes, NFTMarketplace.SaleType saleType, address tokenAddress, uint256 tokenId) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTMarketplace(to).buy(bestRoutes, saleType, tokenAddress, tokenId);

        vm.stopBroadcast();
    }

    function updateTokenPayment(address payable to, address token) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFTMarketplace(to).setTokenPayment(token);

        vm.stopBroadcast();
    }

}

