// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../libraries/LibAuction.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract AuctionFacet {
    function createAuction(
        uint _voteId,
        uint _biddingTime,
        uint _revealTime,
        address _nftAddress,
        uint _nftId,
        uint _price
    ) external {
        LibAuction._createAuction(
            _voteId,
            _biddingTime,
            _revealTime,
            _nftAddress,
            _nftId,
            _price
        );
    }

    function placeHiddenBid(uint256 _voteId) external payable {
        LibAuction._placeHiddenBid(_voteId);
    }

    function withdraw(uint256 _voteId) external {
        LibAuction._withdraw(_voteId);
    }

    function auctionEnd(uint256 _voteId) external {
        LibAuction._auctionEnd(_voteId);
    }

    function revealBid(uint256 _voteId, uint256 _bidAmount) external {
        LibAuction._revealBid(_voteId, _bidAmount);
    }
    function adminWithdrawal() external {
        LibAuction._AdminWithdrawal();
    }

}
