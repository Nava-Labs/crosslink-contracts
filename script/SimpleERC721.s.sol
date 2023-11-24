// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {SimpleERC721} from "../src/mocks/SimpleERC721.sol";

contract DeployMockERC721 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC721 erc721 = new SimpleERC721(
            "PudgyPenguins",
            "PPG",
            "https://ipfs.io/ipfs/bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna/"
        );

        console.log(
            "Mock ERC721 contract deployed with address: ",
            address(erc721)
        );

        vm.stopBroadcast();
    }
}

contract MockERC721Interaction is Script {
    function approve(
        address token,
        address spender,
        uint256 tokenId
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC721(token).approve(spender, tokenId);

        vm.stopBroadcast();
    }

    function transfer(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC721(token).transferFrom(from, to, tokenId);

        vm.stopBroadcast();
    }

    function mint(
        address token,
        uint256 _qty
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleERC721(token).mint(_qty);

        vm.stopBroadcast();
    }


}
