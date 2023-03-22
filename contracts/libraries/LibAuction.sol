 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {Bid, NFT, AuctionStorage } from "./LibAuctionData.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol/";
library LibAuction{


    function onlyBefore(uint time) internal view {
        require(!(block.timestamp >= time), "too late");
       
    }
    function onlyAfter(uint time) internal view{
        require(!(block.timestamp <= time), "Too Early");
        
    }
    function isValidID(uint voteId) internal {
        AuctionStorage storage ds = AuctionSlot();

        require((ds.idUsed[voteId]), "INVALID ID");
    
    }


    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event Withdrawal(address userAddress, uint amount);
    event AuctionCreated(
        address userAddress,
        uint voteID,
        address tokenAddress,
        uint tokenID
    );

    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();

   

    function _createAuction(
        uint voteId,
        uint biddingTime,
        uint revealTime,
        address nftAddress,
        uint nftId,
        uint _price
    ) internal {

        AuctionStorage storage ds = AuctionSlot();
        require(!(ds.idUsed[voteId]), "ID USED");
        require(_price > 0, "INCORRECT PRICE FORMAT");
        processNFT(nftAddress, nftId, voteId, _price);
        ds.idUsed[voteId] = true;
        ds.voteId.push(voteId);
        ds.beneficiary[voteId] = payable(msg.sender);
        ds.biddingEnd[voteId] = block.timestamp + (biddingTime * 1 minutes);
        ds.revealEnd[voteId] = ds.biddingEnd[voteId] + (revealTime * 1 minutes);

        emit AuctionCreated(msg.sender, voteId, nftAddress, nftId);
    }

    function processNFT(
        address _nftAddress,
        uint _nftId,
        uint voteId,
        uint _price
    ) internal {
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftId);
        // IERC721(_nftAddress).Approval(address(this), Moderator, _nftId);
        AuctionStorage storage ds = AuctionSlot();

        IERC721(_nftAddress).approve(ds.Moderator, _nftId);
        ds.auctionNFT[voteId] = NFT({
            nftAddress: _nftAddress,
            nftID: _nftId,
            initialPrice: _price
        });
    }


    function _placeHiddenBid(uint256 _voteId) internal  {

        AuctionStorage storage ds = AuctionSlot();

        require(msg.sender != ds.beneficiary[_voteId], "OWNER CANT BID");
        require((ds.bids[_voteId][msg.sender] == 0), "ALREADY STAKED");
        require(
            (msg.value) > ds.auctionNFT[_voteId].initialPrice,
            "BELOW INITIAL BID"
        );
        isValidID(_voteId);
        ds.bids[_voteId][msg.sender] = _getBytes(msg.sender, msg.value);
    }

    function _getBytes(
        address sender,
        uint256 value
    ) internal pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(sender, value)));
    }

    function _withdraw(uint256 _voteId) internal {
        AuctionStorage storage ds = AuctionSlot();

        require(ds.ended[_voteId], "AUCTION NOT ENDED YET");
        uint amount = ds.pendingReturns[_voteId][msg.sender];
        if (amount > 0) {
            ds.pendingReturns[_voteId][msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            emit Withdrawal(msg.sender, amount);
        } else revert();
    }

    function _auctionEnd(uint256 _voteId) internal {
        // ds.ended[_voteId] = true;
        AuctionStorage storage ds = AuctionSlot();

        require((ds.ended[_voteId] == false), "AUCTION ENDED ALREADY");
        ds.ended[_voteId] = true;
        uint tempAmmount = ds.highestBid[_voteId];
        ds.highestBid[_voteId] = 0;
        (bool success, ) = (ds.beneficiary[_voteId]).call{value: tempAmmount}(
            ""
        );
        if (ds.highestBidder[_voteId] != address(0)) {
            IERC721(ds.auctionNFT[_voteId].nftAddress).transferFrom(
                address(this),
                ds.highestBidder[_voteId],
                ds.auctionNFT[_voteId].nftID
            );
        }
        emit AuctionEnded(ds.highestBidder[_voteId], ds.highestBid[_voteId]);
    }

    function _revealBid(uint256 _voteId, uint256 _bidAmmount)  internal {
        AuctionStorage storage ds = AuctionSlot();

        require(
            (_bidAmmount * 1e18) > ds.auctionNFT[_voteId].initialPrice,
            "INSUFFICIENT BID AMMOUNT"
        );
        bytes4 hiddenBallot = ds.bids[_voteId][msg.sender];
        require(hiddenBallot > 0, "NO HIDDEN BID FOUND");

        require(
            hiddenBallot == _getBytes(msg.sender, _bidAmmount),
            "invalid hash combination"
        );
        onlyBefore(ds.revealEnd[_voteId]);
        onlyAfter(ds.biddingEnd[_voteId]);
        ds.bids[_voteId][msg.sender] = 0;
        if (ds.highestBidder[_voteId] == address(0)) {
            ds.highestBidder[_voteId] = msg.sender;
            ds.highestBid[_voteId] = _bidAmmount;
        } else {
            if (_bidAmmount > ds.highestBid[_voteId]) {
                ds.pendingReturns[_voteId][ds.highestBidder[_voteId]] = ds
                    .highestBid[_voteId];
                ds.highestBidder[_voteId] = msg.sender;
                ds.highestBid[_voteId] = _bidAmmount;
            } else if (_bidAmmount < ds.highestBid[_voteId]) {
                ds.pendingReturns[_voteId][msg.sender] = _bidAmmount;
            } else if (_bidAmmount == ds.highestBid[_voteId]) {
                ds.pendingReturns[_voteId][msg.sender] = _bidAmmount;
            }
        }
    }

    function _AdminWithdrawal() internal {    
        AuctionStorage storage ds = AuctionSlot();
       
        if (msg.sender != ds.Moderator) revert();
        // require(msg.sender == Moderator, "NOT ADMIN");
    
      payable(ds.Moderator).transfer(address(this).balance);
    }
    
    function AuctionSlot() internal pure returns(AuctionStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }


}
