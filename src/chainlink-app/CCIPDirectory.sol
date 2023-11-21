// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract CCIPDirectory {

    struct CrossChainMetadataAddress {
        uint64 chainIdSelector;
        address ccipRouter;
        address linkToken;
        address crossChainApp;
    }

    // Supported Networks
    // uint64 constant chainIdEthereumSepolia = 16015286601757825753;
    // uint64 constant chainIdOptimismGoerli = 2664363617261496610;
    // uint64 constant chainIdAvalancheFuji = 14767482510784806043;
    // uint64 constant chainIdArbitrumTestnet = 6101244977088475029;
    // uint64 constant chainIdPolygonMumbai = 12532609583862916517;
    // uint64 constant chainIdBSCTesnet = 13264668187771770619
    mapping(uint64 => CrossChainMetadataAddress) internal _crossChainMetadataAddress;

    constructor() {
        // sepolia
        _crossChainMetadataAddress[16015286601757825753] = CrossChainMetadataAddress ({
            chainIdSelector: 16015286601757825753,
            ccipRouter: 0xD0daae2231E9CB96b94C8512223533293C3693Bf,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });

        // op goerli
        _crossChainMetadataAddress[2664363617261496610] = CrossChainMetadataAddress ({
            chainIdSelector: 2664363617261496610,
            ccipRouter: 0xEB52E9Ae4A9Fb37172978642d4C141ef53876f26,
            linkToken: 0xdc2CC710e42857672E7907CF474a69B63B93089f,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });

        // fuji
        _crossChainMetadataAddress[14767482510784806043] = CrossChainMetadataAddress ({
            chainIdSelector: 14767482510784806043,
            ccipRouter: 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8,
            linkToken: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });

        // arbitrum goerli
        _crossChainMetadataAddress[6101244977088475029] = CrossChainMetadataAddress ({
            chainIdSelector: 6101244977088475029,
            ccipRouter: 0x88E492127709447A5ABEFdaB8788a15B4567589E,
            linkToken: 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });

        // mumbai
        _crossChainMetadataAddress[12532609583862916517] = CrossChainMetadataAddress ({
            chainIdSelector: 12532609583862916517,
            ccipRouter: 0x70499c328e1E2a3c41108bd3730F6670a44595D1,
            linkToken: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });

        // base goerli
        _crossChainMetadataAddress[5790810961207155433] = CrossChainMetadataAddress ({
            chainIdSelector: 5790810961207155433,
            ccipRouter: 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D,
            linkToken: 0xD886E2286Fd1073df82462ea1822119600Af80b6,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });

        // Bsc Testnet
        _crossChainMetadataAddress[13264668187771770619] = CrossChainMetadataAddress ({
            chainIdSelector: 13264668187771770619,
            ccipRouter: 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2,
            linkToken: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06,
            crossChainApp: 0x0000000000000000000000000000000000000000
        });
        
    }

    function getConfigFromNetwork(
        uint64 chainIdSelector
    )
        internal
        view
         returns (CrossChainMetadataAddress memory)
    {
        return _crossChainMetadataAddress[chainIdSelector];
    }

    function getAllNetworks() public view returns (CrossChainMetadataAddress[4] memory) {
        uint64[4] memory chainIdsSelector = [
            16015286601757825753, // Sepolia
            2664363617261496610, // OP Goerli
            14767482510784806043, // Fuji
            // 6101244977088475029, // Arbitrum Testnet
            // 12532609583862916517, // PolygonMumbai
            // 5790810961207155433, // BaseGoerli
            13264668187771770619 // BSC
        ];

        CrossChainMetadataAddress[4] memory allChainsData;

        for (uint8 i = 0; i < 4; i++) {
            allChainsData[i] = getConfigFromNetwork(chainIdsSelector[i]);
        }

        return allChainsData;
    }

    function getAllNetworksConfig() public view returns (CrossChainMetadataAddress[4] memory) {
        uint64[4] memory chainIdsSelector = [
            16015286601757825753, // Sepolia
            2664363617261496610, // OP Goerli
            14767482510784806043, // Fuji
            // 6101244977088475029, // Arbitrum Testnet
            // 12532609583862916517, // PolygonMumbai
            // 5790810961207155433, // BaseGoerli
            13264668187771770619 // BSC
        ];

        CrossChainMetadataAddress[4] memory allChainsData;

        for (uint8 i = 0; i < 4; i++) {
            allChainsData[i] = getConfigFromNetwork(chainIdsSelector[i]);
        }

        return allChainsData;
    }


    function updateCrossChainApp(uint64[] memory chainSelector, address[] memory crossChainAppAddress) external virtual;

}
