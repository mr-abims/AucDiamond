// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../contracts/facets/AuctionFacet.sol";
import "./MockNFT.sol";
import "./deployDiamond.t.sol";
contract AuctionFacetTest is DiamondDeployer {
    AuctionFacet auctionFacet;
    MockNFT mockNFT;
    address auctioner1 = mkaddr("auctioner1");
    address bidder1 = mkaddr("bidder1");
    address bidder2 = mkaddr("bidder2");
    address bidder3 = mkaddr("bidder3");
    address ogbeni = mkaddr("ogbeni");


    function setUp() public {
         auctionFacet = new AuctionFacet();
         mockNFT = new MockNFT();
    }
    function testCreateAuction() public {
        vm.startPrank(auctioner1);
        mockNFT.mint(address(auctionFacet));
       
         auctionFacet.createAuction(1, 30, 60, address(mockNFT), 0, 0.3 ether);
         vm.stopPrank();
    }

    function testBid() public {
        testCreateAuction();
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        vm.deal(bidder3, 100 ether);


        vm.prank(bidder1);
        auctionFacet.placeHiddenBid{value: 0.4 ether}(1);
         vm.prank(bidder2);
        auctionFacet.placeHiddenBid{value: 1 ether}(1);
         vm.prank(bidder3);
        auctionFacet.placeHiddenBid{value: 0.46 ether}(1);
      console.log(address(auctionFacet).balance);
    }
    function testReveal() public{
        testBid();
        vm.warp(31 minutes);
        vm.prank(bidder1);
        
        auctionFacet.revealBid(1, 0.4 ether);
        vm.prank(bidder2);
        
        auctionFacet.revealBid(1, 1 ether);
        vm.prank(ogbeni);
         auctionFacet.auctionEnd(1);
        vm.prank(bidder1);
        
        auctionFacet.withdraw(1);
        vm.prank(address(0));
         auctionFacet.adminWithdrawal();
        


    }
    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}