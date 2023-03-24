// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../lib/forge-std/src/Script.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/AuctionFacet.sol";
import "../contracts/Diamond.sol";
contract AddFacet is Script, IDiamondCut {
    address DiamondAddr= 0xd5D0F272F4477C8c82B3f507852e8C17F3BcEaDC;
  address  DiamondCutAddr=0xcfD808D0cDA5FB1d2D4E825A960e5bedd56A33bc;
address loupeAddr= 0x943bDD9e258f9fcd98b64D38486E9b18b6E6EFE0;

address ownershipAddr= 0xF73F182e06E98d87958d2cBB2c5552dA3773bCb1;

address auctionAddr= 0x2Ca27701436972e066D747D9D3e4e4DeB94b79e8;




    function run() public {

        FacetCut[] memory cuts = new FacetCut[](3);
        cuts[0] = (
            FacetCut({
                facetAddress: loupeAddr,
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cuts[1] = (
            FacetCut({
                facetAddress: ownershipAddr,
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        
        cuts[2] = (
            FacetCut({
                facetAddress: auctionAddr,
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionFacet")
            })
        );
        // Upgrading diamond
        uint256 key = vm.envUint("key");
        vm.startBroadcast(key);
        IDiamondCut (DiamondAddr).diamondCut(cuts, address(0), "");
        IDiamondLoupe(DiamondAddr).facetAddresses();
        vm.stopBroadcast();
    }
 function generateSelectors(string memory _facetName)
        internal
        returns (bytes4[] memory selectors)
    {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}